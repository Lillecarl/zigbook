const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var population = std.StringHashMap(u32).init(allocator);
    defer population.deinit();

    try population.put("Seattle", 750_000);
    try population.put("Austin", 950_000);
    try population.put("Boston", 690_000);

    var iter = population.iterator();
    while (iter.next()) |entry| {
        std.debug.print("City: {s}, Population: {d}\n", .{ entry.key_ptr.*, entry.value_ptr.* });
    }
}
