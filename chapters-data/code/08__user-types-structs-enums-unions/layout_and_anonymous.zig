const std = @import("std");

// Chapter 8 — Layout (packed/extern) and anonymous structs/tuples

const Packed = packed struct {
    a: u3,
    b: u5,
};

const Extern = extern struct {
    a: u32,
    b: u8,
};

pub fn main() !void {
    // Packed bit-fields combine into a single byte.
    std.debug.print("packed.size={d}\n", .{@sizeOf(Packed)});

    // Extern layout matches the C ABI (padding may be inserted).
    std.debug.print("extern.size={d} align={d}\n", .{ @sizeOf(Extern), @alignOf(Extern) });

    // Anonymous struct (tuple) literals and destructuring.
    const pair = .{ "x", 42 };
    const name = @field(pair, "0");
    const value = @field(pair, "1");
    std.debug.print("pair[0]={s} pair[1]={d} via names: {s}/{d}\n", .{ @field(pair, "0"), @field(pair, "1"), name, value });
}
