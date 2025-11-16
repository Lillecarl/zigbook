const std = @import("std");

fn stdout() *std.Io.Writer {
    const g = struct {
        var buf: [1024]u8 = undefined;
        var w = std.fs.File.stdout().writer(&buf);
    };
    return &g.w.interface;
}

const WithStuff = struct {
    x: u32,
    pub const message: []const u8 = "compile-time constant";
    pub fn greet() []const u8 {
        return "hello";
    }
};

pub fn main() !void {
    const out = stdout();

    // Detect declarations and fields at comptime
    comptime {
        if (!@hasDecl(WithStuff, "greet")) {
            @compileError("missing greet decl");
        }
        if (!@hasField(WithStuff, "x")) {
            @compileError("missing field x");
        }
    }

    // @embedFile: include file contents in the binary at build time
    const embedded = @embedFile("hello.txt");

    try out.print("has greet: {}\n", .{@hasDecl(WithStuff, "greet")});
    try out.print("has field x: {}\n", .{@hasField(WithStuff, "x")});
    try out.print("message: {s}\n", .{WithStuff.message});
    try out.print("embedded:\n{s}", .{embedded});
    try out.flush();
}
