const std = @import("std");

pub fn main() !void {
    const value: i32 = 255;
    const pi = 3.14159;
    const large = 123.0;

    std.debug.print("Decimal: {d}\n", .{value});
    std.debug.print("Hexadecimal (lowercase): {x}\n", .{value});
    std.debug.print("Hexadecimal (uppercase): {X}\n", .{value});
    std.debug.print("Binary: {b}\n", .{value});
    std.debug.print("Octal: {o}\n", .{value});
    std.debug.print("Float with 2 decimals: {d:.2}\n", .{pi});
    std.debug.print("Scientific notation: {e}\n", .{large});
    std.debug.print("Padded: {d:0>5}\n", .{42});
    std.debug.print("Right-aligned: {d:>5}\n", .{42});
}
