const std = @import("std");

fn testImplGood(allocator: std.mem.Allocator, length: usize) !void {
    const a = try allocator.alloc(u8, length);
    defer allocator.free(a);
    const b = try allocator.alloc(u8, length);
    defer allocator.free(b);
}

// No "bad" implementation here; see leak_demo_fail.zig for a dedicated failing example.

test "OOM injection: good implementation is leak-free" {
    const allocator = std.testing.allocator;
    try std.testing.checkAllAllocationFailures(allocator, testImplGood, .{32});
}

// Intentionally not included: a "bad" implementation under checkAllAllocationFailures
// will cause the test runner to fail due to leak logging, even if you expect the error.
// See leak_demo_fail.zig for a dedicated failing example.
