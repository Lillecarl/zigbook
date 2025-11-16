const std = @import("std");
const pathutil = @import("path_util.zig").pathutil;

pub fn main() !void {
    var out_buf: [2048]u8 = undefined;
    var out_writer = std.fs.File.stdout().writer(&out_buf);
    const out = &out_writer.interface;

    // Demonstrate join
    const j1 = try pathutil.joinAlloc(std.heap.page_allocator, &.{ "a", "b", "c" });
    defer std.heap.page_allocator.free(j1);
    try out.print("join a,b,c => {s}\n", .{j1});

    const j2 = try pathutil.joinAlloc(std.heap.page_allocator, &.{ "/", "usr/", "/bin" });
    defer std.heap.page_allocator.free(j2);
    try out.print("join /,usr/,/bin => {s}\n", .{j2});

    // Demonstrate basename/dirpath
    const p = "/home/user/docs/report.txt";
    try out.print("basename({s}) => {s}\n", .{ p, pathutil.basename(p) });
    try out.print("dirpath({s}) => {s}\n", .{ p, pathutil.dirpath(p) });

    // Extension helpers
    try out.print("extname({s}) => {s}\n", .{ p, pathutil.extname(p) });
    const changed = try pathutil.changeExtAlloc(std.heap.page_allocator, p, "md");
    defer std.heap.page_allocator.free(changed);
    try out.print("changeExt({s}, md) => {s}\n", .{ p, changed });

    try out.flush();
}
