// Entry point for a minimal Zig build system example.
// This demonstrates the simplest possible Zig program structure that can be built
// using the Zig build system, showing the basic main function and standard library import.
const std = @import("std");

pub fn main() !void {
    std.debug.print("Hello from minimal build!\n", .{});
}
