//! Swaps two words using the x86 xchg instruction with memory constraints.
const std = @import("std");
const builtin = @import("builtin");

pub fn swapXchg(a: *u32, b: *u32) void {
    if (builtin.cpu.arch != .x86_64) @compileError("swapXchg requires x86_64");

    var lhs = a.*;
    var rhs = b.*;
    asm volatile ("xchgl %[left], %[right]"
        : [left] "+r" (lhs),
          [right] "+r" (rhs),
    );
    a.* = lhs;
    b.* = rhs;
}

test "swapXchg swaps values" {
    var lhs: u32 = 1;
    var rhs: u32 = 2;
    swapXchg(&lhs, &rhs);
    try std.testing.expectEqual(@as(u32, 2), lhs);
    try std.testing.expectEqual(@as(u32, 1), rhs);
}
