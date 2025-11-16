
// This example demonstrates thread-safe one-time initialization using atomic operations.
// Multiple threads attempt to initialize a shared resource, but only one succeeds in
// performing the expensive initialization exactly once.

const std = @import("std");

// Represents the initialization state using atomic operations
const State = enum(u8) { idle, busy, ready };

// Global state tracking the initialization lifecycle
var once_state: State = .idle;
// The shared configuration value that will be initialized once
var config_value: i32 = 0;
// Counter to verify that initialization only happens once
var init_calls: u32 = 0;

// Simulates an expensive initialization operation that should only run once.
// Uses atomic operations to safely increment the call counter and set the config value.
fn expensiveInit() void {
    // Simulate expensive work with a sleep
    std.Thread.sleep(2 * std.time.ns_per_ms);
    // Atomically increment the initialization call counter
    _ = @atomicRmw(u32, &init_calls, .Add, 1, .seq_cst);
    // Atomically store the initialized value with release semantics
    @atomicStore(i32, &config_value, 9157, .release);
}

// Ensures expensiveInit() is called exactly once across multiple threads.
// Uses a state machine with compare-and-swap to coordinate thread access.
fn callOnce() void {
    while (true) {
        // Check the current state with acquire semantics to see initialization results
        switch (@atomicLoad(State, &once_state, .acquire)) {
            // Initialization complete, return immediately
            .ready => return,
            // Another thread is initializing, yield and retry
            .busy => {
                std.Thread.yield() catch {};
                continue;
            },
            // Not yet initialized, attempt to claim initialization responsibility
            .idle => {
                // Try to atomically transition from idle to busy
                // If successful (returns null), this thread wins and will initialize
                // If it fails (returns the actual value), another thread won, so retry
                if (@cmpxchgStrong(State, &once_state, .idle, .busy, .acq_rel, .acquire)) |_| {
                    continue;
                }
                // This thread successfully claimed the initialization
                break;
            },
        }
    }

    // Perform the one-time initialization
    expensiveInit();
    // Mark initialization as complete with release semantics
    @atomicStore(State, &once_state, .ready, .release);
}

// Arguments passed to each worker thread
const WorkerArgs = struct {
    results: []i32,
    index: usize,
};

// Worker thread function that calls the once-initialization and reads the result.
fn worker(args: WorkerArgs) void {
    // Ensure initialization happens (blocks until complete if another thread is initializing)
    callOnce();
    // Read the initialized value with acquire semantics
    const value = @atomicLoad(i32, &config_value, .acquire);
    // Store the observed value in the thread's result slot
    args.results[args.index] = value;
}

pub fn main() !void {
    // Reset global state for demonstration
    once_state = .idle;
    config_value = 0;
    init_calls = 0;

    // Set up memory allocation
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const worker_count: usize = 4;

    // Allocate array to collect results from each thread
    const results = try allocator.alloc(i32, worker_count);
    defer allocator.free(results);
    // Initialize all result slots to -1 to detect if any thread fails
    for (results) |*slot| slot.* = -1;

    // Allocate array to hold thread handles
    const threads = try allocator.alloc(std.Thread, worker_count);
    defer allocator.free(threads);

    // Spawn all worker threads
    for (threads, 0..) |*thread, index| {
        thread.* = try std.Thread.spawn(.{}, worker, .{WorkerArgs{
            .results = results,
            .index = index,
        }});
    }

    // Wait for all threads to complete
    for (threads) |thread| {
        thread.join();
    }

    // Read final values after all threads complete
    const final_value = @atomicLoad(i32, &config_value, .acquire);
    const called = @atomicLoad(u32, &init_calls, .seq_cst);

    // Set up buffered output
    var stdout_buffer: [256]u8 = undefined;
    var stdout_state = std.fs.File.stdout().writer(&stdout_buffer);
    const out = &stdout_state.interface;

    // Print the value observed by each thread (should all be 9157)
    for (results, 0..) |value, index| {
        try out.print("thread {d} observed {d}\n", .{ index, value });
    }
    // Verify initialization was called exactly once
    try out.print("init calls: {d}\n", .{called});
    // Display the final configuration value
    try out.print("config value: {d}\n", .{final_value});
    try out.flush();
}
