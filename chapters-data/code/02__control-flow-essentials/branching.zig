// File: chapters-data/code/02__control-flow-essentials/branching.zig

// Demonstrates Zig's control flow and optional handling capabilities
const std = @import("std");

/// Determines a descriptive label for an optional integer value.
/// Uses labeled blocks to handle different numeric cases cleanly.
/// Returns a string classification based on the value's properties.
fn chooseLabel(value: ?i32) []const u8 {
    // Unwrap the optional value using payload capture syntax
    return if (value) |v| blk: {
        // Check for zero first
        if (v == 0) break :blk "zero";
        // Positive numbers
        if (v > 0) break :blk "positive";
        // All remaining cases are negative
        break :blk "negative";
    } else "missing"; // Handle null case
}

pub fn main() !void {
    // Array containing both present and absent (null) values
    const samples = [_]?i32{ 5, 0, null, -3 };

    // Iterate through samples with index capture
    for (samples, 0..) |item, index| {
        // Classify each sample value
        const label = chooseLabel(item);
        // Display the index and corresponding label
        std.debug.print("sample {d}: {s}\n", .{ index, label });
    }
}
