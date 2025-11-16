const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const result = try std.fmt.allocPrint(allocator, "The answer is {d}", .{42});
    defer allocator.free(result);

    std.debug.print("Dynamic: {s}\n", .{result});
}
