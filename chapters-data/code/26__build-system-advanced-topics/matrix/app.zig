
// Import the standard library for core functionality
const std = @import("std");
// Import builtin to access compile-time target and optimization information
const builtin = @import("builtin");

/// Demonstrates how to access and display build-time configuration information.
/// This function prints the target architecture, OS, ABI, and optimization mode
/// that were configured during the build process.
pub fn main() !void {
    // Create a fixed-size buffer for stdout operations
    var stdout_buffer: [256]u8 = undefined;
    // Initialize a buffered writer for stdout to improve performance
    var writer_state = std.fs.File.stdout().writer(&stdout_buffer);
    // Get the writer interface for output operations
    const out = &writer_state.interface;

    // Print the target triple: CPU architecture, operating system, and ABI
    try out.print("target: {s}-{s}-{s}\n", .{
        @tagName(builtin.target.cpu.arch),
        @tagName(builtin.target.os.tag),
        @tagName(builtin.target.abi),
    });
    // Print the optimization mode (Debug, ReleaseSafe, ReleaseFast, or ReleaseSmall)
    try out.print("optimize: {s}\n", .{@tagName(builtin.mode)});
    // Flush the buffer to ensure all output is written to stdout
    try out.flush();
}
