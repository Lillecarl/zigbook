//! Utility module demonstrating exported functions and formatted output.
//! This module is part of the build system deep dive chapter, showing how to create
//! library functions that can be exported and used across different build artifacts.

const std = @import("std");

/// Doubles the input integer value.
/// This function is exported and can be called from C or other languages.
/// Uses the `export` keyword to make it available in the compiled library.
export fn util_double(x: i32) i32 {
    return x * 2;
}

/// Squares the input integer value.
/// This function is exported and can be called from C or other languages.
/// Uses the `export` keyword to make it available in the compiled library.
export fn util_square(x: i32) i32 {
    return x * x;
}

/// Formats a message with an integer value into the provided buffer.
/// This is a public Zig function (not exported) that demonstrates buffer-based formatting.
/// 
/// Returns a slice of the buffer containing the formatted message, or an error if
/// the buffer is too small to hold the formatted output.
pub fn formatMessage(buf: []u8, value: i32) ![]const u8 {
    return std.fmt.bufPrint(buf, "Value: {d}", .{value});
}
