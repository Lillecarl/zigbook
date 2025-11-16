const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var list = std.SegmentedList(i32, 4){};
    defer list.deinit(allocator);

    try list.append(allocator, 10);
    try list.append(allocator, 20);

    // Take a pointer to the first element
    const first_ptr = list.at(0);
    std.debug.print("First item: {d}\n", .{first_ptr.*});

    // Append more items - pointer remains valid!
    try list.append(allocator, 30);

    std.debug.print("First item (after append): {d}\n", .{first_ptr.*});
    std.debug.print("List length: {d}\n", .{list.len});
}
