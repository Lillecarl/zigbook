// This program demonstrates performance measurement and comparison of different
// sorting algorithms using Zig's built-in Timer for benchmarking.
const std = @import("std");

// Number of elements to sort in each benchmark run
const sample_count = 1024;

/// Generates a deterministic array of random u32 values for benchmarking.
/// Uses a fixed seed to ensure reproducible results across multiple runs.
/// @return: Array of 1024 pseudo-random u32 values
fn generateData() [sample_count]u32 {
    var data: [sample_count]u32 = undefined;
    // Initialize PRNG with fixed seed for deterministic output
    var prng = std.Random.DefaultPrng.init(0xfeed_beef_dead_cafe);
    var random = prng.random();
    // Fill each array slot with a random 32-bit unsigned integer
    for (&data) |*slot| {
        slot.* = random.int(u32);
    }
    return data;
}

/// Measures the execution time of a sorting function on a copy of the input data.
/// Creates a scratch buffer to avoid modifying the original data, allowing
/// multiple measurements on the same dataset.
/// @param sortFn: Compile-time sorting function to benchmark
/// @param source: Source data to sort (remains unchanged)
/// @return: Elapsed time in nanoseconds
fn measureSort(
    comptime sortFn: anytype,
    source: []const u32,
) !u64 {
    // Create scratch buffer to preserve original data
    var scratch: [sample_count]u32 = undefined;
    std.mem.copyForwards(u32, scratch[0..], source);

    // Start high-resolution timer immediately before sort operation
    var timer = try std.time.Timer.start();
    // Execute the sort with ascending comparison function
    sortFn(u32, scratch[0..], {}, std.sort.asc(u32));
    // Capture elapsed nanoseconds
    return timer.read();
}

pub fn main() !void {
    // Generate shared dataset for all sorting algorithms
    var dataset = generateData();

    // Benchmark each sorting algorithm on identical data
    const block_ns = try measureSort(std.sort.block, dataset[0..]);
    const heap_ns = try measureSort(std.sort.heap, dataset[0..]);
    const insertion_ns = try measureSort(std.sort.insertion, dataset[0..]);

    // Display raw timing results along with build mode
    std.debug.print("optimize-mode={s}\n", .{@tagName(@import("builtin").mode)});
    std.debug.print("block sort     : {d} ns\n", .{block_ns});
    std.debug.print("heap sort      : {d} ns\n", .{heap_ns});
    std.debug.print("insertion sort : {d} ns\n", .{insertion_ns});

    // Calculate relative performance metrics using block sort as baseline
    const baseline = @as(f64, @floatFromInt(block_ns));
    const heap_speedup = baseline / @as(f64, @floatFromInt(heap_ns));
    const insertion_slowdown = @as(f64, @floatFromInt(insertion_ns)) / baseline;

    // Display comparative analysis showing speedup/slowdown factors
    std.debug.print("heap speedup over block: {d:.2}x\n", .{heap_speedup});
    std.debug.print("insertion slowdown vs block: {d:.2}x\n", .{insertion_slowdown});
}
