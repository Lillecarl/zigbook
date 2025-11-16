const std = @import("std");
const builtin = @import("builtin");
const root = @import("root");
const extras = @import("extras.zig");

pub fn helperSymbol() void {}

pub fn main() !void {
    var stdout_buffer: [512]u8 = undefined;
    var file_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const out = &file_writer.interface;

    try out.print("root has main(): {}\n", .{@hasDecl(root, "main")});
    try out.print("root has helperSymbol(): {}\n", .{@hasDecl(root, "helperSymbol")});
    try out.print("std namespace type: {s}\n", .{@typeName(@TypeOf(@import("std")))});
    try out.print("current build mode: {s}\n", .{@tagName(builtin.mode)});
    try out.print("extras.greet(): {s}\n", .{extras.greet()});

    try out.flush();
}
