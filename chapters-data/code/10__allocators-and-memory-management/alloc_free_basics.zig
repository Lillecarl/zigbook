const std = @import("std");

pub fn main() !void {
    const allocator = std.heap.page_allocator; // OS-backed; fast & simple

    // Allocate a small buffer and fill it.
    const buf = try allocator.alloc(u8, 5);
    defer allocator.free(buf);

    for (buf, 0..) |*b, i| b.* = 'a' + @as(u8, @intCast(i));
    std.debug.print("buf: {s}\n", .{buf});

    // Create/destroy a single item.
    const Point = struct { x: i32, y: i32 };
    const p = try allocator.create(Point);
    defer allocator.destroy(p);
    p.* = .{ .x = 7, .y = -3 };
    std.debug.print("point: (x={}, y={})\n", .{ p.x, p.y });

    // Allocate a null-terminated string (sentinel). Great for C APIs.
    var hello = try allocator.allocSentinel(u8, 5, 0);
    defer allocator.free(hello);
    @memcpy(hello[0..5], "hello");
    std.debug.print("zstr: {s}\n", .{hello});
}
