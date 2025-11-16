const std = @import("std");
const builder_mod = @import("string_builder.zig");
const StringBuilder = builder_mod.StringBuilder;
const Stats = builder_mod.Stats;

/// Container for built string and its allocation statistics
const Result = struct {
    text: []u8,
    stats: Stats,
};

/// Calculates the total byte length of all string segments
/// Used to pre-compute capacity requirements for efficient allocation
fn totalLength(parts: []const []const u8) usize {
    var sum: usize = 0;
    for (parts) |segment| sum += segment.len;
    return sum;
}

/// Builds a formatted string without pre-allocating capacity
/// Demonstrates the cost of incremental growth through multiple reallocations
/// Separators are spaces, with newlines every 8th segment
fn buildNaive(allocator: std.mem.Allocator, parts: []const []const u8) !Result {
    // Initialize with default capacity (0 bytes)
    // Builder will grow dynamically as content is appended
    var builder = StringBuilder.init(allocator);
    defer builder.deinit();

    for (parts, 0..) |segment, index| {
        // Each append may trigger reallocation if capacity is insufficient
        try builder.append(segment);
        if (index + 1 < parts.len) {
            // Insert newline every 8 segments, space otherwise
            const sep = if ((index + 1) % 8 == 0) "\n" else " ";
            try builder.append(sep);
        }
    }

    // Capture allocation statistics showing multiple growth operations
    const stats = builder.snapshot();
    const text = try builder.toOwnedSlice();
    return .{ .text = text, .stats = stats };
}

/// Builds a formatted string with pre-calculated capacity
/// Demonstrates performance optimization by eliminating reallocations
/// Produces identical output to buildNaive but with fewer allocations
fn buildPlanned(allocator: std.mem.Allocator, parts: []const []const u8) !Result {
    var builder = StringBuilder.init(allocator);
    defer builder.deinit();

    // Calculate exact space needed: all segments plus separator count
    // Separators: n-1 for n parts (no separator after last segment)
    const separators = if (parts.len == 0) 0 else parts.len - 1;
    // Pre-allocate all required capacity in a single allocation
    try builder.ensureUnusedCapacity(totalLength(parts) + separators);

    for (parts, 0..) |segment, index| {
        // Append operations never reallocate due to pre-allocation
        try builder.append(segment);
        if (index + 1 < parts.len) {
            // Insert newline every 8 segments, space otherwise
            const sep = if ((index + 1) % 8 == 0) "\n" else " ";
            try builder.append(sep);
        }
    }

    // Capture statistics showing single allocation with no growth
    const stats = builder.snapshot();
    const text = try builder.toOwnedSlice();
    return .{ .text = text, .stats = stats };
}

pub fn main() !void {
    // Initialize leak-detecting allocator to verify proper cleanup
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        if (gpa.deinit() == .leak) std.log.err("leaked allocations detected", .{});
    }
    const allocator = gpa.allocator();

    // Sample data: 32 Greek letters and astronomy terms
    // Large enough to demonstrate multiple reallocations in naive approach
    const segments = [_][]const u8{
        "alpha",
        "beta",
        "gamma",
        "delta",
        "epsilon",
        "zeta",
        "eta",
        "theta",
        "iota",
        "kappa",
        "lambda",
        "mu",
        "nu",
        "xi",
        "omicron",
        "pi",
        "rho",
        "sigma",
        "tau",
        "upsilon",
        "phi",
        "chi",
        "psi",
        "omega",
        "aurora",
        "borealis",
        "cosmos",
        "nebula",
        "quasar",
        "pulsar",
        "singularity",
        "zenith",
    };

    // Build string without capacity planning
    // Stats will show multiple allocations and growth operations
    const naive = try buildNaive(allocator, &segments);
    defer allocator.free(naive.text);

    // Build string with exact capacity pre-allocation
    // Stats will show single allocation with no growth
    const planned = try buildPlanned(allocator, &segments);
    defer allocator.free(planned.text);

    // Compare allocation statistics side-by-side
    // Demonstrates the efficiency gain from capacity planning
    std.debug.print(
        "naive -> {any}\n{s}\n\nplanned -> {any}\n{s}\n",
        .{ naive.stats, naive.text, planned.stats, planned.text },
    );
}
