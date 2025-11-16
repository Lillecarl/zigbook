const std = @import("std");
const builder_mod = @import("string_builder.zig");
const StringBuilder = builder_mod.StringBuilder;

pub fn main() !void {
    // Initialize a general-purpose allocator with leak detection
    // This allocator tracks all allocations and reports leaks on deinit
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        if (gpa.deinit() == .leak) std.log.err("leaked allocations detected", .{});
    }
    const allocator = gpa.allocator();

    // Create a StringBuilder with 64 bytes of initial capacity
    // Pre-allocating reduces reallocation overhead for known content size
    var builder = try StringBuilder.initCapacity(allocator, 64);
    defer builder.deinit();

    // Build report header using basic string concatenation
    try builder.append("Report\n======\n");
    try builder.append("source: dynamic builder\n\n");

    // Define structured data for report generation
    // Each item represents a category with its count
    const items = [_]struct {
        name: []const u8,
        count: usize,
    }{
        .{ .name = "widgets", .count = 7 },
        .{ .name = "gadgets", .count = 13 },
        .{ .name = "doodads", .count = 2 },
    };

    // Obtain a writer interface for formatted output
    // This allows using std.fmt.format-style print operations
    var writer = builder.writer();
    for (items, 0..) |item, index| {
        // Format each item as a numbered list entry with name and count
        try writer.print("* {d}. {s}: {d}\n", .{ index + 1, item.name, item.count });
    }

    // Capture allocation statistics before adding summary
    // Snapshot preserves metrics for analysis without affecting builder state
    const snapshot = builder.snapshot();
    try writer.print("\nsummary: appended {d} entries\n", .{items.len});

    // Transfer ownership of the constructed string to caller
    // After this call, builder is reset and cannot be reused without re-initialization
    const result = try builder.toOwnedSlice();
    defer allocator.free(result);

    // Display the generated report alongside allocation statistics
    std.debug.print("{s}\n---\n{any}\n", .{ result, snapshot });
}
