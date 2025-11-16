const std = @import("std");

/// Performs addition with overflow detection and saturation.
/// If overflow occurs, returns the maximum u8 value instead of wrapping.
/// Uses @setRuntimeSafety(false) in the non-overflow path for performance.
fn guardedUncheckedAdd(a: u8, b: u8) u8 {
    // Check if addition would overflow using builtin overflow detection
    const sum = @addWithOverflow(a, b);
    const overflow = sum[1] == 1;
    // Saturate to max value on overflow
    if (overflow) return std.math.maxInt(u8);

    // Safe path: disable runtime safety checks for this addition
    // since we've already verified no overflow will occur
    return blk: {
        @setRuntimeSafety(false);
        break :blk a + b;
    };
}

/// Performs addition without runtime safety checks.
/// This allows the operation to wrap on overflow (undefined behavior in safe mode).
/// Demonstrates completely disabling safety for a function scope.
fn wrappingAddUnsafe(a: u8, b: u8) u8 {
    // Disable all runtime safety checks for this entire function
    @setRuntimeSafety(false);
    return a + b;
}

// Verifies that guardedUncheckedAdd correctly handles both normal addition
// and overflow saturation scenarios.
test "guarded unchecked addition saturates on overflow" {
    // Normal case: 120 + 80 = 200 (no overflow)
    try std.testing.expectEqual(@as(u8, 200), guardedUncheckedAdd(120, 80));
    // Overflow case: 240 + 30 = 270 > 255, should saturate to 255
    try std.testing.expectEqual(std.math.maxInt(u8), guardedUncheckedAdd(240, 30));
}

// Demonstrates that wrappingAddUnsafe produces the same wrapped result
// as @addWithOverflow when overflow occurs.
test "wrapping addition mirrors overflow tuple" {
    // @addWithOverflow returns [wrapped_result, overflow_bit]
    const sum = @addWithOverflow(@as(u8, 250), @as(u8, 10));
    // Verify overflow occurred (250 + 10 = 260 > 255)
    try std.testing.expect(sum[1] == 1);
    // Verify wrapped result matches unchecked addition (260 % 256 = 4)
    try std.testing.expectEqual(sum[0], wrappingAddUnsafe(250, 10));
}
