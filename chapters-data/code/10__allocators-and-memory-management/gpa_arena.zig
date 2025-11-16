const std = @import("std");

pub fn main() !void {
    // GeneralPurposeAllocator with leak detection on deinit.
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .init;
    defer {
        const leaked = gpa.deinit() == .leak;
        if (leaked) @panic("leak detected");
    }
    const alloc = gpa.allocator();

    const nums = try alloc.alloc(u64, 4);
    defer alloc.free(nums);

    for (nums, 0..) |*n, i| n.* = @as(u64, i + 1);
    var sum: u64 = 0;
    for (nums) |n| sum += n;
    std.debug.print("gpa sum: {}\n", .{sum});

    // Arena allocator: bulk free with deinit.
    var arena_inst = std.heap.ArenaAllocator.init(alloc);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();

    const msg = try arena.dupe(u8, "temporary allocations live here");
    std.debug.print("arena msg len: {}\n", .{msg.len});
}
