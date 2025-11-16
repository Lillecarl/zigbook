const std = @import("std");
const builtin = @import("builtin");

// Enum representing the possible states of task execution
// Uses explicit u8 backing to ensure consistent size across platforms
const TaskState = enum(u8) { idle, threaded_done, inline_done };

// Global atomic state tracking whether task ran inline or in a separate thread
// Atomics ensure thread-safe access even though single-threaded builds won't spawn threads
var task_state = std.atomic.Value(TaskState).init(.idle);

// Simulates a task that runs in a separate thread
// Includes a small delay to demonstrate asynchronous execution
fn threadedTask() void {
    std.Thread.sleep(1 * std.time.ns_per_ms);
    // Release ordering ensures all prior writes are visible to threads that acquire this value
    task_state.store(.threaded_done, .release);
}

// Simulates a task that runs inline in the main thread
// Used as fallback when threading is disabled at compile time
fn inlineTask() void {
    // Release ordering maintains consistency with the threaded path
    task_state.store(.inline_done, .release);
}

pub fn main() !void {
    // Set up buffered stdout writer for efficient output
    var stdout_buffer: [256]u8 = undefined;
    var stdout_state = std.fs.File.stdout().writer(&stdout_buffer);
    const out = &stdout_state.interface;

    // Reset state to idle with sequential consistency
    // seq_cst provides strongest ordering guarantees for initialization
    task_state.store(.idle, .seq_cst);

    // Check compile-time flag to determine execution strategy
    // builtin.single_threaded is true when compiled with -fsingle-threaded
    if (builtin.single_threaded) {
        try out.print("single-threaded build; running task inline\n", .{});
        // Execute task directly without spawning a thread
        inlineTask();
    } else {
        try out.print("multi-threaded build; spawning worker\n", .{});
        // Spawn separate thread to execute task concurrently
        var worker = try std.Thread.spawn(.{}, threadedTask, .{});
        // Block until worker thread completes
        worker.join();
    }

    // Acquire ordering ensures we observe all writes made before the release store
    const final_state = task_state.load(.acquire);
    
    // Convert enum state to human-readable string for output
    const label = switch (final_state) {
        .idle => "idle",
        .threaded_done => "threaded_done",
        .inline_done => "inline_done",
    };

    // Display final execution state and flush buffer to ensure output is visible
    try out.print("task state: {s}\n", .{label});
    try out.flush();
}
