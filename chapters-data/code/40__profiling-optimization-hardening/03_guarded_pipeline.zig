
// This example demonstrates input validation and error handling patterns in Zig,
// showing how to create guarded data processing pipelines with proper bounds checking.

const std = @import("std");

// Custom error set for parsing and validation operations
const ParseError = error{
    EmptyInput,      // Returned when input contains only whitespace or is empty
    InvalidNumber,   // Returned when input cannot be parsed as a valid number
    OutOfRange,      // Returned when parsed value is outside acceptable bounds
};

/// Parses and validates a text input as a u32 limit value.
/// Ensures the value is between 1 and 10,000 inclusive.
/// Whitespace is automatically trimmed from input.
fn parseLimit(text: []const u8) ParseError!u32 {
    // Remove leading and trailing whitespace characters
    const trimmed = std.mem.trim(u8, text, " \t\r\n");
    if (trimmed.len == 0) return error.EmptyInput;

    // Attempt to parse as base-10 unsigned 32-bit integer
    const value = std.fmt.parseInt(u32, trimmed, 10) catch return error.InvalidNumber;
    
    // Enforce bounds: reject zero and values exceeding maximum threshold
    if (value == 0 or value > 10_000) return error.OutOfRange;
    return value;
}

/// Applies a throttling limit to a work queue, ensuring safe processing bounds.
/// Returns the actual number of items that can be processed, which is the minimum
/// of the requested limit and the available work length.
fn throttle(work: []const u8, limit: u32) ParseError!usize {
    // Precondition: limit must be positive (enforced at runtime in debug builds)
    std.debug.assert(limit > 0);

    // Guard against empty work queues
    if (work.len == 0) return error.EmptyInput;

    // Calculate safe processing limit by taking minimum of requested limit and work size
    // Cast is safe because we're taking the minimum value
    const safe_limit = @min(limit, @as(u32, @intCast(work.len)));
    return safe_limit;
}

// Test: Verify that valid numeric strings are correctly parsed
test "valid limit parses" {
    try std.testing.expectEqual(@as(u32, 750), try parseLimit("750"));
}

// Test: Ensure whitespace-only input is properly rejected
test "empty input rejected" {
    try std.testing.expectError(error.EmptyInput, parseLimit("   \n"));
}

// Test: Verify throttling respects the parsed limit and work size
test "in-flight throttling respects guard" {
    const limit = try parseLimit("32");
    // Work length (4) is less than limit (32), so expect work length
    try std.testing.expectEqual(@as(usize, 4), try throttle("hard", limit));
}

// Test: Validate multiple inputs meet the maximum threshold requirement
// Demonstrates compile-time iteration for testing multiple scenarios
test "validate release configurations" {
    const inputs = [_][]const u8{ "8", "9999", "500" };
    // Compile-time loop unrolls test cases for each input value
    inline for (inputs) |value| {
        const parsed = try parseLimit(value);
        // Ensure parsed values never exceed the defined maximum
        try std.testing.expect(parsed <= 10_000);
    }
}
