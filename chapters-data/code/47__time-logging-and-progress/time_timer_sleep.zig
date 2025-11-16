const std = @import("std");

pub fn main() !void {
    var t = try std.time.Timer.start();
    std.Thread.sleep(50 * std.time.ns_per_ms);
    const ns = t.read();
    // Ensure we slept at least 50ms
    if (ns < 50 * std.time.ns_per_ms) return error.TimerResolutionTooLow;
    // Print a stable message
    std.debug.print("Timer OK\n", .{});
}
