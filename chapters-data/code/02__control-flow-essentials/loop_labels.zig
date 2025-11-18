// File: chapters-data/code/02__control-flow-essentials/loop_labels.zig

// Demonstrates labeled loops and while-else constructs in Zig
const std = @import("std");

/// Searches for the first row where both elements are even numbers.
/// Uses a while loop with continue statements to skip invalid rows.
/// Returns the zero-based index of the matching row, or null if none found.
fn findFirstEvenPair(rows: []const [2]i32) ?usize {
    // Track current row index during iteration
    var row: usize = 0;
    // while-else construct: break provides value, else provides fallback
    const found = while (row < rows.len) : (row += 1) {
        // Extract current pair for examination
        const pair = rows[row];
        // Skip row if first element is odd
        if (@mod(pair[0], 2) != 0) continue;
        // Skip row if second element is odd
        if (@mod(pair[1], 2) != 0) continue;
        // Both elements are even: return this row's index
        break row;
    } else null; // No matching row found after exhausting all rows

    return found;
}

pub fn main() !void {
    // Test data containing pairs of integers with mixed even/odd values
    const grid = [_][2]i32{
        .{ 3, 7 }, // Both odd
        .{ 2, 4 }, // Both even (target)
        .{ 5, 6 }, // Mixed
    };

    // Search for first all-even pair and report result
    if (findFirstEvenPair(&grid)) |row| {
        std.debug.print("first all-even row: {d}\n", .{row});
    } else {
        std.debug.print("no all-even rows\n", .{});
    }

    // Demonstrate labeled loop for multi-level break control
    var attempts: usize = 0;
    // Label the outer while loop to enable breaking from nested for loop
    outer: while (attempts < grid.len) : (attempts += 1) {
        // Iterate through columns of current row with index capture
        for (grid[attempts], 0..) |value, column| {
            // Check if target value is found
            if (value == 4) {
                // Report location of target value
                std.debug.print(
                    "found target value at row {d}, column {d}\n",
                    .{ attempts, column },
                );
                // Break out of both loops using the outer label
                break :outer;
            }
        }
    }
}
