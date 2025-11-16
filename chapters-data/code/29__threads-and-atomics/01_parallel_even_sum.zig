
// This example demonstrates parallel computation using threads and atomic operations in Zig.
// It calculates the sum of even numbers in an array by distributing work across multiple threads.
const std = @import("std");

// Arguments passed to each worker thread for parallel processing
const WorkerArgs = struct {
    slice: []const u64,                  // The subset of numbers this worker should process
    sum: *std.atomic.Value(u64),         // Shared atomic counter for thread-safe accumulation
};

// Worker function that accumulates even numbers from its assigned slice
// Each thread runs this function independently on its own data partition
fn accumulate(args: WorkerArgs) void {
    // Use a local variable to minimize atomic operations (performance optimization)
    var local_total: u64 = 0;
    for (args.slice) |value| {
        if (value % 2 == 0) {
            local_total += value;
        }
    }

    // Atomically add the local result to the shared sum using sequentially consistent ordering
    // This ensures all threads see a consistent view of the shared state
    _ = args.sum.fetchAdd(local_total, .seq_cst);
}

pub fn main() !void {
    // Set up memory allocator with automatic leak detection
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Allocate array of 64 numbers for demonstration
    var numbers = try allocator.alloc(u64, 64);
    defer allocator.free(numbers);

    // Initialize array with values following the pattern: index * 7 + 3
    for (numbers, 0..) |*slot, index| {
        slot.* = @as(u64, @intCast(index * 7 + 3));
    }

    // Initialize shared atomic counter that all threads will safely update
    var shared_sum = std.atomic.Value(u64).init(0);

    // Determine optimal number of worker threads based on available CPU cores
    const cpu_count = std.Thread.getCpuCount() catch 1;
    const desired = if (cpu_count == 0) 1 else cpu_count;
    // Don't create more threads than we have numbers to process
    const worker_limit = @min(numbers.len, desired);

    // Allocate thread handles for parallel workers
    var threads = try allocator.alloc(std.Thread, worker_limit);
    defer allocator.free(threads);

    // Calculate chunk size, rounding up to ensure all elements are covered
    const chunk = (numbers.len + worker_limit - 1) / worker_limit;

    // Spawn worker threads, distributing the array into roughly equal chunks
    var start: usize = 0;
    var spawned: usize = 0;
    while (start < numbers.len and spawned < worker_limit) : (spawned += 1) {
        const remaining = numbers.len - start;
        // Give the last thread all remaining elements to handle uneven divisions
        const take = if (worker_limit - spawned == 1) remaining else @min(chunk, remaining);
        const end = start + take;

        // Spawn thread with its assigned slice and shared accumulator
        threads[spawned] = try std.Thread.spawn(.{}, accumulate, .{WorkerArgs{
            .slice = numbers[start..end],
            .sum = &shared_sum,
        }});

        start = end;
    }

    // Track how many threads were actually spawned (may be less than worker_limit)
    const used_threads = spawned;

    // Wait for all worker threads to complete their work
    for (threads[0..used_threads]) |thread| {
        thread.join();
    }

    // Read the final accumulated result from the atomic shared sum
    const even_sum = shared_sum.load(.seq_cst);

    // Perform sequential calculation to verify correctness of parallel computation
    var sequential: u64 = 0;
    for (numbers) |value| {
        if (value % 2 == 0) {
            sequential += value;
        }
    }

    // Set up buffered stdout writer for efficient output
    var stdout_buffer: [256]u8 = undefined;
    var stdout_state = std.fs.File.stdout().writer(&stdout_buffer);
    const out = &stdout_state.interface;

    // Display results: thread count and both parallel and sequential sums
    try out.print("spawned {d} worker(s)\n", .{used_threads});
    try out.print("even sum (threads): {d}\n", .{even_sum});
    try out.print("even sum (sequential check): {d}\n", .{sequential});
    try out.flush();
}
