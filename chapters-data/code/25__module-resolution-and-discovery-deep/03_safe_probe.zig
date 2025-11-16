const std = @import("std");
const plugins = @import("plugins.zig");

pub fn main() !void {
    var stdout_buffer: [512]u8 = undefined;
    var file_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const out = &file_writer.interface;

    if (comptime @hasDecl(plugins.namespace, "install")) {
        try out.print("plugin discovered: {s}\n", .{plugins.namespace.install()});
    } else {
        try out.print("no plugin available; continuing safely\n", .{});
    }

    try out.flush();
}
