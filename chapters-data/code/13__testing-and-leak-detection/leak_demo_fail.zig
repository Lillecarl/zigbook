const std = @import("std");

// This test intentionally leaks to demonstrate the testing allocator's leak detection.
// Do NOT copy this pattern into real code; see leak_demo_fix.zig for the fix.

test "leak detection catches a missing free" {
    const allocator = std.testing.allocator;

    // Intentionally leak this allocation by not freeing it.
    const buf = try allocator.alloc(u8, 64);

    // Touch the memory so optimizers can't elide the allocation.
    for (buf) |*b| b.* = 0xAA;

    // No free on purpose:
    // allocator.free(buf);
}
