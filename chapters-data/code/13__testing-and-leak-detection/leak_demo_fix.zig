const std = @import("std");

test "no leak when freeing properly" {
    // Use the testing allocator, which tracks allocations and detects leaks
    const allocator = std.testing.allocator;

    // Allocate a 64-byte buffer on the heap
    const buf = try allocator.alloc(u8, 64);
    // Schedule deallocation to happen at scope exit (ensures cleanup)
    defer allocator.free(buf);

    // Fill the buffer with 0xAA pattern to demonstrate usage
    for (buf) |*b| b.* = 0xAA;
    
    // When the test exits, defer runs allocator.free(buf)
    // The testing allocator verifies all allocations were freed
}
