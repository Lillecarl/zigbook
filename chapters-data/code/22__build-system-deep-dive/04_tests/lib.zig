/// Computes the factorial of a non-negative integer using recursion.
/// The factorial of n (denoted as n!) is the product of all positive integers less than or equal to n.
/// Base case: factorial(0) = factorial(1) = 1
/// Recursive case: factorial(n) = n * factorial(n-1)
pub fn factorial(n: u32) u32 {
    // Base case: 0! and 1! both equal 1
    if (n <= 1) return 1;
    // Recursive case: multiply n by factorial of (n-1)
    return n * factorial(n - 1);
}

// Test: Verify that the factorial of 0 returns 1 (base case)
test "factorial of 0 is 1" {
    const std = @import("std");
    try std.testing.expectEqual(@as(u32, 1), factorial(0));
}

// Test: Verify that the factorial of 5 returns 120 (5! = 5*4*3*2*1 = 120)
test "factorial of 5 is 120" {
    const std = @import("std");
    try std.testing.expectEqual(@as(u32, 120), factorial(5));
}

// Test: Verify that the factorial of 1 returns 1 (base case)
test "factorial of 1 is 1" {
    const std = @import("std");
    try std.testing.expectEqual(@as(u32, 1), factorial(1));
}
