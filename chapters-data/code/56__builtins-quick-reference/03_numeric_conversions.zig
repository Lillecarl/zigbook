//! Exercises numeric conversion builtins with guarded tests.
const std = @import("std");

fn toU8Lossy(value: u16) u8 {
    return @truncate(value);
}

fn toI32(value: f64) i32 {
    return @intFromFloat(value);
}

fn widenU16(value: u8) u16 {
    return @intCast(value);
}

test "truncate discards high bits" {
    try std.testing.expectEqual(@as(u8, 0x34), toU8Lossy(0x1234));
}

test "intFromFloat matches floor for positive range" {
    try std.testing.expectEqual(@as(i32, 42), toI32(42.9));
}
test "intCast widens without loss" {
    try std.testing.expectEqual(@as(u16, 255), widenU16(255));
}
