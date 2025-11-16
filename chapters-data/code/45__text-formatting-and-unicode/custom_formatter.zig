const std = @import("std");

const Point = struct {
    x: i32,
    y: i32,

    pub fn format(self: @This(), writer: *std.Io.Writer) std.Io.Writer.Error!void {
        try writer.print("({d}, {d})", .{ self.x, self.y });
    }
};

pub fn main() !void {
    const p = Point{ .x = 10, .y = 20 };
    std.debug.print("Point: {f}\n", .{p});
}
