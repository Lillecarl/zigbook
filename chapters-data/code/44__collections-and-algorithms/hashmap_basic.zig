const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.StringHashMap(i32).init(allocator);
    defer map.deinit();

    try map.put("foo", 42);
    try map.put("bar", 100);

    if (map.get("foo")) |value| {
        std.debug.print("Value for 'foo': {d}\n", .{value});
    }

    std.debug.print("Contains 'bar': {}\n", .{map.contains("bar")});
    std.debug.print("Contains 'baz': {}\n", .{map.contains("baz")});

    _ = map.remove("foo");
    std.debug.print("After removing 'foo', contains: {}\n", .{map.contains("foo")});
}
