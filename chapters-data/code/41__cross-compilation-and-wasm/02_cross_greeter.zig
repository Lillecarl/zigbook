
// Import the standard library for printing and platform utilities
const std = @import("std");
// Import builtin to access compile-time target information
const builtin = @import("builtin");

// Entry point that demonstrates cross-compilation by displaying target platform information
pub fn main() void {
    // Print the target platform's CPU architecture, OS, and ABI
    // Uses builtin.target to access compile-time target information
    std.debug.print("hello from {s}-{s}-{s}!\n", .{
        @tagName(builtin.target.cpu.arch),
        @tagName(builtin.target.os.tag),
        @tagName(builtin.target.abi),
    });

    // Retrieve the platform-specific executable file extension (e.g., ".exe" on Windows, "" on Linux)
    const suffix = std.Target.Os.Tag.exeFileExt(builtin.target.os.tag, builtin.target.cpu.arch);
    std.debug.print("default executable suffix: {s}\n", .{suffix});
}
