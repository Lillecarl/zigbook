const std = @import("std");

pub fn main() !void {
    const two_min_s = 2 * std.time.s_per_min;
    const hour_ns = std.time.ns_per_hour;
    std.debug.print("2 min = {d} s\n1 h = {d} ns\n", .{ two_min_s, hour_ns });
}
