const std = @import("std");

// Chapter 8 — Enums: integer repr, conversions, exhaustiveness
//
// Demonstrates defining an enum with explicit integer representation,
// converting between enum and integer using @intFromEnum and @enumFromInt,
// and pattern matching with exhaustiveness checking.
//
// Usage: 
//    zig run enum_roundtrip.zig

const Mode = enum(u8) {
    Idle = 0,
    Busy = 1,
    Paused = 2,
};

fn describe(m: Mode) []const u8 {
    return switch (m) {
        .Idle => "idle",
        .Busy => "busy",
        .Paused => "paused",
    };
}

pub fn main() !void {
    const m: Mode = .Busy;
    const int_val: u8 = @intFromEnum(m);
    std.debug.print("m={s} int={d}\n", .{ describe(m), int_val });

    // Round-trip using @enumFromInt; the integer must map to a declared tag.
    const m2: Mode = @enumFromInt(2);
    std.debug.print("m2={s} int={d}\n", .{ describe(m2), @intFromEnum(m2) });
}
