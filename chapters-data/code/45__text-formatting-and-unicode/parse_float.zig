const std = @import("std");

pub fn main() !void {
    const pi = try std.fmt.parseFloat(f64, "3.14159");
    std.debug.print("Parsed: {d}\n", .{pi});

    const scientific = try std.fmt.parseFloat(f64, "1.23e5");
    std.debug.print("Scientific: {d}\n", .{scientific});

    const infinity = try std.fmt.parseFloat(f64, "inf");
    std.debug.print("Special (inf): {d}\n", .{infinity});
}
