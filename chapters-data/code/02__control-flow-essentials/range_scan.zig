// File: chapters-data/code/02__control-flow-essentials/range_scan.zig

// Demonstrates while loops with labeled breaks and continue statements
const std = @import("std");

pub fn main() !void {
    // Sample data array containing mixed positive, negative, and zero values
    const data = [_]i16{ 12, 5, 9, -1, 4, 0 };

    // Search for the first negative value in the array
    var index: usize = 0;
    // while-else construct: break provides value, else provides fallback
    const first_negative = while (index < data.len) : (index += 1) {
        // Check if current element is negative
        if (data[index] < 0) break index;
    } else null; // No negative value found after scanning entire array

    // Report the result of the negative value search
    if (first_negative) |pos| {
        std.debug.print("first negative at index {d}\n", .{pos});
    } else {
        std.debug.print("no negatives in sequence\n", .{});
    }

    // Accumulate sum of even numbers until encountering zero
    var sum: i64 = 0;
    var count: usize = 0;

    // Label the loop to enable explicit break targeting
    accumulate: while (count < data.len) : (count += 1) {
        const value = data[count];
        // Stop accumulation if zero is encountered
        if (value == 0) {
            std.debug.print("encountered zero, breaking out\n", .{});
            break :accumulate;
        }
        // Skip odd values using labeled continue
        if (@mod(value, 2) != 0) continue :accumulate;
        // Add even values to the running sum
        sum += value;
    }

    // Display the accumulated sum of even values before zero
    std.debug.print("sum of even prefix values = {d}\n", .{sum});
}
