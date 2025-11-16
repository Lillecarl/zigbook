//! Reads the x86 time stamp counter using inline assembly outputs.
const std = @import("std");
const builtin = @import("builtin");

pub fn readTimeStampCounter() u64 {
    if (builtin.cpu.arch != .x86_64) @compileError("rdtsc example requires x86_64");

    var lo: u32 = undefined;
    var hi: u32 = undefined;
    asm volatile ("rdtsc"
        : [low] "={eax}" (lo),
          [high] "={edx}" (hi),
    );
    return (@as(u64, hi) << 32) | @as(u64, lo);
}

test "readTimeStampCounter returns non-zero" {
    const a = readTimeStampCounter();
    const b = readTimeStampCounter();
    // The counter advances monotonically; allow equality in case calls land in the same cycle.
    try std.testing.expect(b >= a);
}
