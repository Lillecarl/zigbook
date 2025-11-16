const std = @import("std");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const argv = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, argv);

    const argc = argv.len;
    const program_name = if (argc > 0)
        std.fs.path.basename(std.mem.sliceTo(argv[0], 0))
    else
        "<unknown>";

    std.debug.print("argv[0].basename = {s}\n", .{program_name});
    std.debug.print("argc = {d}\n", .{argc});
    if (argc > 1) {
        std.debug.print("user args present\n", .{});
    } else {
        std.debug.print("user args absent\n", .{});
    }
}
