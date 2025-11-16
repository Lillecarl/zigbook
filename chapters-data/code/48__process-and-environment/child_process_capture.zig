const std = @import("std");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var child = std.process.Child.init(&.{ "zig", "version" }, allocator);
    child.stdin_behavior = .Ignore;
    child.stdout_behavior = .Pipe;
    child.stderr_behavior = .Pipe;

    try child.spawn();
    defer if (child.term == null) {
        _ = child.kill() catch {};
    };

    var stdout_buffer = try std.ArrayList(u8).initCapacity(allocator, 0);
    defer stdout_buffer.deinit(allocator);

    var stderr_buffer = try std.ArrayList(u8).initCapacity(allocator, 0);
    defer stderr_buffer.deinit(allocator);

    try std.process.Child.collectOutput(child, allocator, &stdout_buffer, &stderr_buffer, 16 * 1024);

    const term = try child.wait();

    const stdout_trimmed = std.mem.trimRight(u8, stdout_buffer.items, "\r\n");

    switch (term) {
        .Exited => |code| {
            if (code != 0) return error.UnexpectedExit;
        },
        else => return error.UnexpectedExit,
    }

    std.debug.print("zig version -> {s}\n", .{stdout_trimmed});
    std.debug.print("stderr bytes -> {d}\n", .{stderr_buffer.items.len});
}
