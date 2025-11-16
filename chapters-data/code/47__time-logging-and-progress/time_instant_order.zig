const std = @import("std");

pub fn main() !void {
    const a = try std.time.Instant.now();
    std.Thread.sleep(1 * std.time.ns_per_ms);
    const b = try std.time.Instant.now();
    if (b.order(a) == .lt) return error.InstantNotMonotonic;
    std.debug.print("Instant OK\n", .{});
}
