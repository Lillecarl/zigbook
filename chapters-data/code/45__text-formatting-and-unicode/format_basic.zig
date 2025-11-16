const std = @import("std");

pub fn main() !void {
    var buffer: [100]u8 = undefined;
    var fbs = std.io.fixedBufferStream(&buffer);
    const writer = fbs.writer();

    try writer.print("Answer={d}, pi={d:.2}", .{ 42, 3.14159 });

    std.debug.print("Formatted: {s}\n", .{fbs.getWritten()});
}
