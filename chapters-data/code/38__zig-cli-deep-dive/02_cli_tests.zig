const std = @import("std");

/// Calculates the sum of all integers in the provided slice.
/// Returns 0 for an empty slice.
fn sum(values: []const i32) i32 {
    var total: i32 = 0;
    // Accumulate all values in the slice
    for (values) |value| total += value;
    return total;
}

/// Calculates the product of all integers in the provided slice.
/// Returns 1 for an empty slice (multiplicative identity).
fn product(values: []const i32) i32 {
    var total: i32 = 1;
    // Multiply each value with the running total
    for (values) |value|
        total *= value;
    return total;
}

// Verifies that sum correctly adds positive integers
test "sum-of-three" {
    try std.testing.expectEqual(@as(i32, 42), sum(&.{ 20, 10, 12 }));
}

// Verifies that sum handles mixed positive and negative integers correctly
test "sum-mixed-signs" {
    try std.testing.expectEqual(@as(i32, -1), sum(&.{ 4, -3, -2 }));
}

// Verifies that product correctly multiplies positive integers
test "product-positive" {
    try std.testing.expectEqual(@as(i32, 120), product(&.{ 2, 3, 4, 5 }));
}

// Verifies that product correctly handles negative integers,
// resulting in a negative product when an odd number of negatives are present
test "product-negative" {
    try std.testing.expectEqual(@as(i32, -18), product(&.{ 3, -3, 2 }));
}
