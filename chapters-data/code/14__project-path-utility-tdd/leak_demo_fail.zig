const std = @import("std");
const testing = std.testing;
const pathutil = @import("path_util.zig").pathutil;

test "deliberate leak caught by testing allocator" {
    const joined = try pathutil.joinAlloc(testing.allocator, &.{ "/", "tmp", "demo" });
    // Intentionally forget to free: allocator leak should be detected by the runner
    // defer testing.allocator.free(joined);
    try testing.expect(std.mem.endsWith(u8, joined, "demo"));
}
