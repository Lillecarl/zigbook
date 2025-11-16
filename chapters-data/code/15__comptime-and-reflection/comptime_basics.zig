const std = @import("std");

fn stdout() *std.Io.Writer {
    // Buffered stdout writer per Zig 0.15.2 (Writergate)
    // We keep the buffer static so it survives for main's duration.
    const g = struct {
        var buf: [1024]u8 = undefined;
        var w = std.fs.File.stdout().writer(&buf);
    };
    return &g.w.interface;
}

// Compute a tiny lookup table at compile time; print at runtime.
fn squaresTable(comptime N: usize) [N]u64 {
    var out: [N]u64 = undefined;
    comptime var i: usize = 0;
    inline while (i < N) : (i += 1) {
        out[i] = @as(u64, i) * @as(u64, i);
    }
    return out;
}

pub fn main() !void {
    const out = stdout();

    // Basic comptime evaluation
    const a = comptime 2 + 3; // evaluated at compile time
    try out.print("a (comptime 2+3) = {}\n", .{a});

    // @inComptime reports whether we are currently executing at compile-time
    const during_runtime = @inComptime();
    try out.print("@inComptime() during runtime: {}\n", .{during_runtime});

    // Generate a squares table at compile time
    const table = squaresTable(8);
    try out.print("squares[0..8): ", .{});
    var i: usize = 0;
    while (i < table.len) : (i += 1) {
        if (i != 0) try out.print(",", .{});
        try out.print("{}", .{table[i]});
    }
    try out.print("\n", .{});

    try out.flush();
}
