const std = @import("std");

fn tee(r: *std.Io.Reader, a: *std.Io.Writer, b: *std.Io.Writer) !void {
    while (true) {
        const chunk = r.peekGreedy(1) catch |err| switch (err) {
            error.EndOfStream => break,
            error.ReadFailed => return err,
        };
        try a.writeAll(chunk);
        try b.writeAll(chunk);
        r.toss(chunk.len);
    }
}

pub fn main() !void {
    const input = "tee me please";
    var r: std.Io.Reader = .fixed(input);

    var abuf: [64]u8 = undefined;
    var bbuf: [64]u8 = undefined;
    var a: std.Io.Writer = .fixed(&abuf);
    var b: std.Io.Writer = .fixed(&bbuf);

    try tee(&r, &a, &b);

    std.debug.print("A: {s}\nB: {s}\n", .{ a.buffered(), b.buffered() });
}
