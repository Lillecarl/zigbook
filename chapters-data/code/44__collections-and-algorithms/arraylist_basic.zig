const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var list: std.ArrayList(i32) = .empty;
    defer list.deinit(allocator);

    try list.append(allocator, 10);
    try list.append(allocator, 20);
    try list.append(allocator, 30);

    for (list.items, 0..) |item, i| {
        std.debug.print("Item {d}: {d}\n", .{ i, item });
    }

    const popped = list.pop();
    std.debug.print("Popped: {d}\n", .{popped.?});
    std.debug.print("Remaining length: {d}\n", .{list.items.len});
}
