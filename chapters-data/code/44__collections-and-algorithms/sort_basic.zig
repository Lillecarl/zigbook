const std = @import("std");

fn lessThan(context: void, a: i32, b: i32) bool {
    _ = context;
    return a < b;
}

fn greaterThan(context: void, a: i32, b: i32) bool {
    _ = context;
    return a > b;
}

pub fn main() !void {
    var numbers = [_]i32{ 5, 2, 8, 1, 10 };

    std.sort.pdq(i32, &numbers, {}, lessThan);
    std.debug.print("Sorted ascending: {any}\n", .{numbers});

    std.sort.pdq(i32, &numbers, {}, greaterThan);
    std.debug.print("Sorted descending: {any}\n", .{numbers});
}
