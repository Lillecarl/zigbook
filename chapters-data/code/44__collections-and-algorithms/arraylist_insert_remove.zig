const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var list: std.ArrayList(i32) = .empty;
    defer list.deinit(allocator);

    try list.appendSlice(allocator, &.{ 1, 2, 3, 4 });

    // Insert 99 at index 1
    try list.insert(allocator, 1, 99);
    std.debug.print("After insert at 1: {any}\n", .{list.items});

    // Remove at index 2 (shifts elements)
    _ = list.orderedRemove(2);
    std.debug.print("After orderedRemove at 2: {any}\n", .{list.items});

    // Remove at index 1 (swaps with last, no shift)
    _ = list.swapRemove(1);
    std.debug.print("After swapRemove at 1: {any}\n", .{list.items});
}
