
// This file demonstrates different safety modes in Zig and how to handle
// conversions with varying levels of runtime checking.

const std = @import("std");

/// Converts an ASCII digit character to its numeric value without runtime safety checks.
/// This function uses an assert to document the precondition that the input must be
/// a valid ASCII digit ('0'-'9'). The @setRuntimeSafety(false) directive disables
/// runtime integer overflow checks for the subtraction and cast operations.
/// 
/// Precondition: byte must be in the range ['0', '9']
/// Returns: The numeric value (0-9) as a u4
pub fn asciiDigitToValueUnchecked(byte: u8) u4 {
    // Assert documents the contract: caller must provide a valid ASCII digit
    std.debug.assert(byte >= '0' and byte <= '9');
    
    // Block with runtime safety disabled for performance-critical paths
    return blk: {
        // Disable runtime overflow/underflow checks for this conversion
        @setRuntimeSafety(false);
        // Safe cast because precondition guarantees result fits in u4 (0-9)
        break :blk @intCast(byte - '0');
    };
}

/// Converts an ASCII digit character to its numeric value with error handling.
/// This function validates the input at runtime and returns an error if the
/// byte is not a valid ASCII digit, making it safe to use with untrusted input.
/// 
/// Returns: The numeric value (0-9) as a u4, or error.InvalidDigit if invalid
pub fn asciiDigitToValue(byte: u8) !u4 {
    // Validate input is within valid ASCII digit range
    if (byte < '0' or byte > '9') return error.InvalidDigit;
    // Safe cast: validation ensures result is in range 0-9
    return @intCast(byte - '0');
}

// Verifies that the unchecked conversion produces correct results for all valid inputs.
// Tests all ASCII digits to ensure the assert-backed function maintains correctness
// even when runtime safety is disabled internally.
test "assert-backed conversion stays safe across modes" {
    // Iterate over all valid ASCII digit characters at compile time
    inline for ("0123456789") |ch| {
        // Verify unchecked function produces same result as direct conversion
        try std.testing.expectEqual(@as(u4, @intCast(ch - '0')), asciiDigitToValueUnchecked(ch));
    }
}

// Verifies that the error-returning conversion properly rejects invalid input.
// Ensures that error handling path works correctly and provides meaningful diagnostics.
test "error path preserves diagnosability" {
    // Verify that non-digit characters return the expected error
    try std.testing.expectError(error.InvalidDigit, asciiDigitToValue('z'));
}
