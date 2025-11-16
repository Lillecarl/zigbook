// This program demonstrates how to access and display Zig's built-in compilation
// information through the `builtin` module. It's used in the zigbook to teach
// readers about build system introspection and standard options.

// Import the standard library for debug printing capabilities
const std = @import("std");
// Import builtin module to access compile-time information about the target
// platform, CPU architecture, and optimization mode
const builtin = @import("builtin");

// Main entry point that prints compilation target information
// Returns an error union to handle potential I/O failures from debug.print
pub fn main() !void {
    // Print the target architecture (e.g., x86_64, aarch64) and operating system
    // (e.g., linux, windows) by extracting tag names from the builtin constants
    std.debug.print("Target: {s}-{s}\n", .{
        @tagName(builtin.cpu.arch),
        @tagName(builtin.os.tag),
    });
    // Print the optimization mode (Debug, ReleaseSafe, ReleaseFast, or ReleaseSmall)
    // that was specified during compilation
    std.debug.print("Optimize: {s}\n", .{@tagName(builtin.mode)});
}
