const std = @import("std");

// Chapter 8 — Unions: tagged and untagged
//
// Demonstrates a tagged union (with enum discriminant) and an untagged union
// (without discriminant). Tagged unions are safe and idiomatic; untagged
// unions are advanced and unsafe if used incorrectly.
//
// Usage: 
//    zig run union_demo.zig

const Kind = enum { number, text };

const Value = union(Kind) {
    number: i64,
    text: []const u8,
};

// Untagged union (advanced): requires external tracking and is unsafe if used wrong.
const Raw = union { u: u32, i: i32 };

pub fn main() !void {
    var v: Value = .{ .number = 42 };
    printValue("start: ", v);

    v = .{ .text = "hi" };
    printValue("update: ", v);

    // Untagged example: write as u32, read as i32 (bit reinterpret).
    const r = Raw{ .u = 0xFFFF_FFFE }; // -2 as signed 32-bit
    const as_i: i32 = @bitCast(r.u);
    std.debug.print("raw u=0x{X:0>8} i={d}\n", .{ r.u, as_i });
}

fn printValue(prefix: []const u8, v: Value) void {
    switch (v) {
        .number => |n| std.debug.print("{s}number={d}\n", .{ prefix, n }),
        .text => |s| std.debug.print("{s}{s}\n", .{ prefix, s }),
    }
}
