// File: chapters-data/code/02__control-flow-essentials/switch_examples.zig

// Import the standard library for I/O operations
const std = @import("std");

// Define an enum representing different compilation modes
const Mode = enum { fast, safe, tiny };

/// Converts a numeric score into a descriptive text message.
/// Demonstrates switch expressions with ranges, multiple values, and catch-all cases.
/// Returns a string literal describing the score's progress level.
fn describeScore(score: u8) []const u8 {
    return switch (score) {
        0 => "no progress",           // Exact match for zero
        1...3 => "warming up",         // Range syntax: matches 1, 2, or 3
        4, 5 => "halfway there",       // Multiple discrete values
        6...9 => "almost done",        // Range: matches 6 through 9
        10 => "perfect run",           // Maximum valid score
        else => "out of range",        // Catch-all for any other value
    };
}

pub fn main() !void {
    // Array of test scores to demonstrate switch behavior
    const samples = [_]u8{ 0, 2, 5, 8, 10, 12 };
    
    // Iterate through each score and print its description
    for (samples) |score| {
        std.debug.print("{d}: {s}\n", .{ score, describeScore(score) });
    }

    // Demonstrate switch with enum values
    const mode: Mode = .safe;
    
    // Switch on enum to assign different numeric factors based on mode
    // All enum cases must be handled (exhaustive matching)
    const factor = switch (mode) {
        .fast => 32,  // Optimization for speed
        .safe => 16,  // Balanced mode
        .tiny => 4,   // Optimization for size
    };
    
    // Print the selected mode and its corresponding factor
    std.debug.print("mode {s} -> factor {d}\n", .{ @tagName(mode), factor });
}
