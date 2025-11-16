// Import the standard library for I/O and basic functionality
const std = @import("std");
// Import the builtin module to access compile-time build information
const builtin = @import("builtin");

// Compute a human-readable hint about the current optimization mode at compile time.
// This block evaluates once during compilation and embeds the result as a constant string.
const optimize_hint = blk: {
    break :blk switch (builtin.mode) {
        .Debug => "debug symbols and runtime safety checks enabled",
        .ReleaseSafe => "runtime checks on, optimized for safety",
        .ReleaseFast => "optimizations prioritized for speed",
        .ReleaseSmall => "optimizations prioritized for size",
    };
};

/// Entry point for the builtin probe utility.
/// Demonstrates how to query and display compile-time build configuration
/// from the `builtin` module, including Zig version, optimization mode,
/// target platform details, and linking options.
pub fn main() !void {
    // Allocate a buffer for stdout buffering to reduce system calls
    var stdout_buffer: [1024]u8 = undefined;
    // Create a buffered writer for stdout to improve I/O performance
    var file_writer = std.fs.File.stdout().writer(&stdout_buffer);
    // Obtain the generic writer interface for formatted output
    const out = &file_writer.interface;

    // Print the Zig compiler version string embedded at compile time
    try out.print("zig version (compiler): {s}\n", .{builtin.zig_version_string});
    
    // Print the optimization mode and its corresponding description
    try out.print("optimize mode: {s} — {s}\n", .{ @tagName(builtin.mode), optimize_hint });
    
    // Print the target triple: architecture, OS, and ABI
    // These values reflect the platform for which the binary was compiled
    try out.print(
        "target triple: {s}-{s}-{s}\n",
        .{
            @tagName(builtin.target.cpu.arch),
            @tagName(builtin.target.os.tag),
            @tagName(builtin.target.abi),
        },
    );
    
    // Indicate whether the binary was built in single-threaded mode
    try out.print("single-threaded build: {}\n", .{builtin.single_threaded});
    
    // Indicate whether the standard C library (libc) is linked
    try out.print("linking libc: {}\n", .{builtin.link_libc});

    // Compile-time block to conditionally import test helpers when running tests.
    // This demonstrates using `builtin.is_test` to enable test-only code paths.
    comptime {
        if (builtin.is_test) {
            // The root module could enable test-only helpers using this hook.
            _ = @import("test_helpers.zig");
        }
    }

    // Flush the buffered writer to ensure all output is written to stdout
    try out.flush();
}
