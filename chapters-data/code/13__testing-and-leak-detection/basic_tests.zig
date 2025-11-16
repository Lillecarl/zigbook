const std = @import("std");

/// Performs exact integer division, returning an error if the divisor is zero.
/// This function demonstrates error handling in a testable way.
fn divExact(a: i32, b: i32) !i32 {
    // Guard clause: check for division by zero before attempting division
    if (b == 0) return error.DivideByZero;
    // Safe to divide: use @divTrunc for truncating integer division
    return @divTrunc(a, b);
}

test "boolean and equality expectations" {
    // Test basic boolean expression using expect
    // expect() returns an error if the condition is false
    try std.testing.expect(2 + 2 == 4);
    
    // Test type-safe equality with expectEqual
    // Both arguments must be the same type; here we explicitly cast to u8
    try std.testing.expectEqual(@as(u8, 42), @as(u8, 42));
}

test "string equality (bytes)" {
    // Define expected string as a slice of const bytes
    const expected: []const u8 = "hello";
    
    // Create actual string via compile-time concatenation
    // The ++ operator concatenates string literals at compile time
    const actual: []const u8 = "he" ++ "llo";
    
    // Use expectEqualStrings for slice comparison
    // This compares the content of the slices, not just the pointer addresses
    try std.testing.expectEqualStrings(expected, actual);
}

test "expecting an error" {
    // Test that divExact returns the expected error when dividing by zero
    // expectError() succeeds if the function returns the specified error
    try std.testing.expectError(error.DivideByZero, divExact(1, 0));
    
    // Test successful division path
    // We use 'try' to unwrap the success value, then expectEqual to verify it
    // If divExact returns an error here, the test will fail
    try std.testing.expectEqual(@as(i32, 3), try divExact(9, 3));
}
