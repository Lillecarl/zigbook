const std = @import("std");

fn lessThan(context: void, a: i32, b: i32) std.math.Order {
    _ = context;
    return std.math.order(a, b);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var queue = std.PriorityQueue(i32, void, lessThan).init(allocator, {});
    defer queue.deinit();

    try queue.add(10);
    try queue.add(5);
    try queue.add(20);
    try queue.add(1);

    while (queue.removeOrNull()) |item| {
        std.debug.print("Popped: {d}\n", .{item});
    }
}
