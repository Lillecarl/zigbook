//! Keeps error vocabulary tight for a numeric parser so callers can react precisely.
const std = @import("std");

/// Enumerates the failure modes that the parser can surface to its callers.
pub const ParseCountError = error{
    EmptyInput,
    InvalidDigit,
    Overflow,
};

/// Parses a decimal counter while preserving descriptive error information.
pub fn parseCount(input: []const u8) ParseCountError!u32 {
    if (input.len == 0) return ParseCountError.EmptyInput;

    var acc: u64 = 0;
    for (input) |char| {
        if (char < '0' or char > '9') return ParseCountError.InvalidDigit;
        const digit: u64 = @intCast(char - '0');
        acc = acc * 10 + digit;
        if (acc > std.math.maxInt(u32)) return ParseCountError.Overflow;
    }

    return @intCast(acc);
}

test "parseCount reports invalid digits precisely" {
    try std.testing.expectEqual(@as(u32, 42), try parseCount("42"));
    try std.testing.expectError(ParseCountError.InvalidDigit, parseCount("4a"));
    try std.testing.expectError(ParseCountError.EmptyInput, parseCount(""));
    try std.testing.expectError(ParseCountError.Overflow, parseCount("42949672960"));
}
