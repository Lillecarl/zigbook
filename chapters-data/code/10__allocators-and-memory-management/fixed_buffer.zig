const std = @import("std");

pub fn main() !void {
    var backing: [32]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&backing);
    const A = fba.allocator();

    // 3 small allocations should fit.
    const a = try A.alloc(u8, 8);
    const b = try A.alloc(u8, 8);
    const c = try A.alloc(u8, 8);
    _ = a;
    _ = b;
    _ = c;

    // This one should fail (32 total capacity, 24 already used).
    if (A.alloc(u8, 16)) |_| {
        std.debug.print("unexpected success\n", .{});
    } else |err| switch (err) {
        error.OutOfMemory => std.debug.print("fixed buffer OOM as expected\n", .{}),
        else => return err,
    }
}
