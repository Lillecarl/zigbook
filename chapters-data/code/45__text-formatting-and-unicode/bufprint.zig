const std = @import("std");

pub fn main() !void {
    var buffer: [100]u8 = undefined;
    const result = try std.fmt.bufPrint(&buffer, "x={d}, y={d:.2}", .{ 42, 3.14159 });
    std.debug.print("Formatted: {s}\n", .{result});
}
