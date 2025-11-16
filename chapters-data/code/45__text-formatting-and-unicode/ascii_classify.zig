const std = @import("std");

pub fn main() void {
    const chars = [_]u8{ 'A', '5', ' ' };

    for (chars) |c| {
        std.debug.print("'{c}': alpha={}, digit={}, ", .{ c, std.ascii.isAlphabetic(c), std.ascii.isDigit(c) });

        if (c == 'A') {
            std.debug.print("upper={}\n", .{std.ascii.isUpper(c)});
        } else if (c == '5') {
            std.debug.print("upper={}\n", .{std.ascii.isUpper(c)});
        } else {
            std.debug.print("whitespace={}\n", .{std.ascii.isWhitespace(c)});
        }
    }
}
