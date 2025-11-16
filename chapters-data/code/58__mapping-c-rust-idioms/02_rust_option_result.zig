//! Mirrors Rust's Option and Result idioms with Zig optionals and error unions.
const std = @import("std");

pub fn findPortLine(env: []const u8) ?[]const u8 {
    var iter = std.mem.splitScalar(u8, env, '\n');
    while (iter.next()) |line| {
        if (std.mem.startsWith(u8, line, "PORT=")) {
            return line["PORT=".len..];
        }
    }
    return null;
}

pub const ParsePortError = error{
    Missing,
    Invalid,
};

pub fn parsePort(env: []const u8) ParsePortError!u16 {
    const raw = findPortLine(env) orelse return ParsePortError.Missing;
    return std.fmt.parseInt(u16, raw, 10) catch ParsePortError.Invalid;
}

test "findPortLine returns optional when key absent" {
    try std.testing.expectEqual(@as(?[]const u8, null), findPortLine("HOST=zig-lang"));
}

test "parsePort converts parse errors into domain error set" {
    try std.testing.expectEqual(@as(u16, 8080), try parsePort("PORT=8080\n"));
    try std.testing.expectError(ParsePortError.Missing, parsePort("HOST=zig"));
    try std.testing.expectError(ParsePortError.Invalid, parsePort("PORT=xyz"));
}
