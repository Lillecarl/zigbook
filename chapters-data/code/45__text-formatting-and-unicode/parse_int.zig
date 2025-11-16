const std = @import("std");

pub fn main() !void {
    const decimal = try std.fmt.parseInt(i32, "42", 10);
    std.debug.print("Parsed decimal: {d}\n", .{decimal});

    const hex = try std.fmt.parseInt(i32, "FF", 16);
    std.debug.print("Parsed hex: {d}\n", .{hex});

    const binary = try std.fmt.parseInt(i32, "111", 2);
    std.debug.print("Parsed binary: {d}\n", .{binary});

    // Auto-detect base with prefix
    const auto = try std.fmt.parseInt(i32, "0x1234", 0);
    std.debug.print("Auto-detected (0x): {d}\n", .{auto});

    // Error handling
    const result = std.fmt.parseInt(i32, "not_a_number", 10);
    if (result) |_| {
        std.debug.print("Unexpected success\n", .{});
    } else |err| {
        std.debug.print("Parse error: {}\n", .{err});
    }
}
