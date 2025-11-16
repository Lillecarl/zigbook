const std = @import("std");

// Reads at most N bytes from an input using std.Io.Reader.Limited
pub fn main() !void {
    const input = "Hello, world!\nRest is skipped";
    var r: std.Io.Reader = .fixed(input);

    var tmp: [8]u8 = undefined; // buffer backing the limited reader
    var limited = r.limited(.limited(5), &tmp); // allow only first 5 bytes

    var out_buf: [64]u8 = undefined;
    var out: std.Io.Writer = .fixed(&out_buf);

    // Pump until limit triggers EndOfStream for the limited reader
    _ = limited.interface.streamRemaining(&out) catch |err| {
        switch (err) {
            error.WriteFailed, error.ReadFailed => unreachable,
        }
    };

    std.debug.print("{s}\n", .{out.buffered()});
}
