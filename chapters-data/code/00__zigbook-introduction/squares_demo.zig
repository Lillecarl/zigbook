const std = @import("std");

pub fn main() void {
    var i: u32 = 1;
    while (i <= 10) : (i += 1) {
        std.debug.print("{d} squared is {d}\n", .{ i, i * i });
    }
}
