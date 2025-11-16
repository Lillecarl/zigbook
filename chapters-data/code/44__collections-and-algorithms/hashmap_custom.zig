const std = @import("std");

const Point = struct {
    x: i32,
    y: i32,
};

const PointContext = struct {
    pub fn hash(self: @This(), p: Point) u64 {
        _ = self;
        var hasher = std.hash.Wyhash.init(0);
        std.hash.autoHash(&hasher, p.x);
        std.hash.autoHash(&hasher, p.y);
        return hasher.final();
    }

    pub fn eql(self: @This(), a: Point, b: Point) bool {
        _ = self;
        return a.x == b.x and a.y == b.y;
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.HashMap(Point, []const u8, PointContext, 80).init(allocator);
    defer map.deinit();

    try map.put(.{ .x = 10, .y = 20 }, "Alice");
    try map.put(.{ .x = 30, .y = 40 }, "Bob");

    var iter = map.iterator();
    while (iter.next()) |entry| {
        std.debug.print("Point({d}, {d}): {s}\n", .{ entry.key_ptr.x, entry.key_ptr.y, entry.value_ptr.* });
    }

    std.debug.print("Contains (10, 20): {}\n", .{map.contains(.{ .x = 10, .y = 20 })});
}
