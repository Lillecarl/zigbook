const std = @import("std");
const builder_mod = @import("string_builder.zig");
const StringBuilder = builder_mod.StringBuilder;
const Stats = builder_mod.Stats;

/// Container for a generated report and its allocation statistics
const Report = struct {
    text: []u8,
    stats: Stats,
};

/// Builds a text report with random sample data
/// Demonstrates StringBuilder usage with various allocator strategies
fn buildReport(allocator: std.mem.Allocator, label: []const u8, sample_count: usize) !Report {
    // Initialize StringBuilder with the provided allocator
    var builder = StringBuilder.init(allocator);
    defer builder.deinit();

    // Write report header
    try builder.append("label: ");
    try builder.append(label);
    try builder.append("\n");

    // Initialize PRNG with a seed that varies based on sample_count
    // Ensures reproducible but different sequences for different report sizes
    var prng = std.Random.DefaultPrng.init(0x5eed1234 ^ @as(u64, sample_count));
    var random = prng.random();

    // Generate random sample data and accumulate totals
    var total: usize = 0;
    var writer = builder.writer();
    for (0..sample_count) |i| {
        // Each sample represents a random KiB allocation between 8-64
        const chunk = random.intRangeAtMost(u32, 8, 64);
        total += chunk;
        try writer.print("{d}: +{d} KiB\n", .{ i, chunk });
    }

    // Write summary line with aggregated statistics
    try writer.print("total: {d} KiB across {d} samples\n", .{ total, sample_count });

    // Capture allocation statistics before transferring ownership
    const stats = builder.snapshot();
    
    // Transfer ownership of the built string to the caller
    const text = try builder.toOwnedSlice();
    return .{ .text = text, .stats = stats };
}

pub fn main() !void {
    // Arena allocator will reclaim all allocations at once when deinit() is called
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    // Small report: 256-byte stack buffer should be sufficient
    // stackFallback tries stack first, falls back to arena if needed
    var fallback_small = std.heap.stackFallback(256, arena.allocator());
    const small_allocator = fallback_small.get();
    const small = try buildReport(small_allocator, "stack-only", 6);
    defer small_allocator.free(small.text);

    // Large report: 256-byte stack buffer will overflow, forcing arena allocation
    // Demonstrates fallback behavior when stack space is insufficient
    var fallback_large = std.heap.stackFallback(256, arena.allocator());
    const large_allocator = fallback_large.get();
    const large = try buildReport(large_allocator, "needs-arena", 48);
    defer large_allocator.free(large.text);

    // Display both reports with their allocation statistics
    // Stats will reveal which allocator strategy was used (stack vs heap)
    std.debug.print("small buffer ->\n{s}stats: {any}\n\n", .{ small.text, small.stats });
    std.debug.print("large buffer ->\n{s}stats: {any}\n", .{ large.text, large.stats });
}
