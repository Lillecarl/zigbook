const std = @import("std");

// Demonstrates basic buffered writing using the new std.Io.Writer API
// and then flushing to stdout via the older std.io File writer.
pub fn main() !void {
    var buf: [128]u8 = undefined;
    // New streaming Writer backed by a fixed buffer. Writes accumulate until flushed/consumed.
    var w: std.Io.Writer = .fixed(&buf);

    try w.print("Header: {s}\n", .{"I/O adapters"});
    try w.print("Value A: {d}\n", .{42});
    try w.print("Value B: {x}\n", .{0xdeadbeef});

    // Grab buffered bytes and print through std.debug (stdout)
    const buffered = w.buffered();
    std.debug.print("{s}", .{buffered});
}
