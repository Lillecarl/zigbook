const std = @import("std");

const Task = struct {
    name: []const u8,
    priority: u32,
};

fn compareTasks(context: void, a: Task, b: Task) std.math.Order {
    _ = context;
    // Higher priority comes first (max-heap behavior)
    return std.math.order(b.priority, a.priority);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var queue = std.PriorityQueue(Task, void, compareTasks).init(allocator, {});
    defer queue.deinit();

    try queue.add(.{ .name = "Documentation", .priority = 1 });
    try queue.add(.{ .name = "Feature request", .priority = 5 });
    try queue.add(.{ .name = "Critical bug", .priority = 10 });

    while (queue.removeOrNull()) |task| {
        std.debug.print("Processing: {s} (priority {d})\n", .{ task.name, task.priority });
    }
}
