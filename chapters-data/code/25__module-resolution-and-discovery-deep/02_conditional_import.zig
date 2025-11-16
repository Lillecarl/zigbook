const std = @import("std");
const builtin = @import("builtin");

pub fn main() !void {
    comptime {
        if (builtin.mode == .Debug) {
            _ = @import("debug_tools.zig");
        }
    }

    var stdout_buffer: [512]u8 = undefined;
    var file_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const out = &file_writer.interface;

    try out.print("build mode: {s}\n", .{@tagName(builtin.mode)});

    if (comptime builtin.mode == .Debug) {
        const debug = @import("debug_tools.zig");
        try out.print("{s}\n", .{debug.banner});
    } else {
        try out.print("no debug tooling imported\n", .{});
    }

    try out.flush();
}
