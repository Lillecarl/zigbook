const std = @import("std");
const testing = std.testing;
const pathutil = @import("path_util.zig").pathutil;

test "fixed: no leak after adding defer free" {
    const joined = try pathutil.joinAlloc(testing.allocator, &.{ "/", "tmp", "demo" });
    defer testing.allocator.free(joined);
    try testing.expect(std.mem.endsWith(u8, joined, "demo"));
}
