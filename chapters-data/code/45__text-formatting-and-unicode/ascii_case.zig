const std = @import("std");

pub fn main() void {
    const text = "Hello, World!";
    var upper_buf: [50]u8 = undefined;
    var lower_buf: [50]u8 = undefined;

    _ = std.ascii.upperString(&upper_buf, text);
    _ = std.ascii.lowerString(&lower_buf, text);

    std.debug.print("Original: {s}\n", .{text});
    std.debug.print("Uppercase: {s}\n", .{upper_buf[0..text.len]});
    std.debug.print("Lowercase: {s}\n", .{lower_buf[0..text.len]});
}
