const std = @import("std");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var env = std.process.EnvMap.init(allocator);
    defer env.deinit();

    try env.put("APP_MODE", "demo");
    try env.put("HOST", "localhost");
    try env.put("THREADS", "4");

    std.debug.print("pairs = {d}\n", .{env.count()});

    try env.put("APP_MODE", "override");
    std.debug.print("APP_MODE = {s}\n", .{env.get("APP_MODE").?});

    env.remove("THREADS");
    const threads = env.get("THREADS");
    std.debug.print("THREADS present? {s}\n", .{if (threads == null) "no" else "yes"});
}
