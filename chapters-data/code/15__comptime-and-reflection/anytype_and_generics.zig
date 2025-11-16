const std = @import("std");

fn stdout() *std.Io.Writer {
    const g = struct {
        var buf: [2048]u8 = undefined;
        var w = std.fs.File.stdout().writer(&buf);
    };
    return &g.w.interface;
}

// A generic function that accepts any element type and sums a slice.
// We use reflection to print type info at runtime.
pub fn sum(comptime T: type, slice: []const T) T {
    var s: T = 0;
    var i: usize = 0;
    while (i < slice.len) : (i += 1) s += slice[i];
    return s;
}

pub fn describeAny(x: anytype) void {
    const T = @TypeOf(x);
    const out = stdout();
    out.print("value of type {s}: ", .{@typeName(T)}) catch {};
    // best-effort print
    out.print("{any}\n", .{x}) catch {};
}

pub fn main() !void {
    const out = stdout();

    // Explicit type parameter
    const a = [_]u32{ 1, 2, 3, 4 };
    const s1 = sum(u32, &a);
    try out.print("sum(u32,[1,2,3,4]) = {}\n", .{s1});

    // Inferred by helper that forwards T
    const b = [_]u64{ 10, 20 };
    const s2 = sum(u64, &b);
    try out.print("sum(u64,[10,20]) = {}\n", .{s2});

    // anytype descriptor
    describeAny(@as(u8, 42));
    describeAny("hello");

    try out.flush();
}
