const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const arena_allocator = arena.allocator();

    var list: std.ArrayList(i32) = .empty;
    for (0..1000) |i| {
        try list.append(arena_allocator, @intCast(i));
    }
    std.debug.print("List has {d} items\n", .{list.items.len});

    var map = std.AutoHashMap(u32, []const u8).init(arena_allocator);
    for (0..500) |i| {
        try map.put(@intCast(i), "value");
    }
    std.debug.print("Map has {d} entries\n", .{map.count()});

    // No need to call list.deinit() or map.deinit()
    // arena.deinit() frees everything at once
    std.debug.print("All freed at once via arena.deinit()\n", .{});
}
