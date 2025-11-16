const std = @import("std");

const Entity = struct {
    id: u32,
    x: f32,
    y: f32,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var entities = std.MultiArrayList(Entity){};
    defer entities.deinit(allocator);

    try entities.append(allocator, .{ .id = 1, .x = 10.5, .y = 20.3 });
    try entities.append(allocator, .{ .id = 2, .x = 30.1, .y = 40.7 });

    for (0..entities.len) |i| {
        const entity = entities.get(i);
        std.debug.print("Entity {d}: id={d}, x={d}, y={d}\n", .{ i, entity.id, entity.x, entity.y });
    }

    // Access a single field slice for efficient iteration
    const x_coords = entities.items(.x);
    var sum: f32 = 0;
    for (x_coords) |x| {
        sum += x;
    }
    std.debug.print("Sum of x coordinates: {d}\n", .{sum});
}
