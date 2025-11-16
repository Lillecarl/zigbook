const std = @import("std");

pub fn main() !void {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .init;
    defer { _ = gpa.deinit(); }
    const alloc = gpa.allocator();

    var buf = try alloc.alloc(u8, 4);
    defer alloc.free(buf);
    for (buf, 0..) |*b, i| b.* = 'A' + @as(u8, @intCast(i));
    std.debug.print("len={} contents={s}\n", .{ buf.len, buf });

    // Grow using realloc (may move).
    buf = try alloc.realloc(buf, 8);
    for (buf[4..], 0..) |*b, i| b.* = 'a' + @as(u8, @intCast(i));
    std.debug.print("grown len={} contents={s}\n", .{ buf.len, buf });

    // Shrink in-place using resize; remember to slice.
    if (alloc.resize(buf, 3)) {
        buf = buf[0..3];
        std.debug.print("shrunk len={} contents={s}\n", .{ buf.len, buf });
    } else {
        // Fallback when in-place shrink not supported by allocator.
        buf = try alloc.realloc(buf, 3);
        std.debug.print("shrunk (realloc) len={} contents={s}\n", .{ buf.len, buf });
    }
}
