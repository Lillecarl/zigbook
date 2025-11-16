//! Discovery probe utility demonstrating conditional imports and runtime introspection.
//! This module showcases how to use compile-time conditionals to optionally load
//! development tools and query their capabilities at runtime using reflection.

const std = @import("std");
const builtin = @import("builtin");

/// Conditionally import development hooks based on build mode.
/// In Debug mode, imports the full dev_probe module with diagnostic capabilities.
/// In other modes (ReleaseSafe, ReleaseFast, ReleaseSmall), provides a minimal
/// stub implementation to avoid loading unnecessary development tooling.
///
/// This pattern enables zero-cost abstractions where development features are
/// completely elided from release builds while maintaining a consistent API.
pub const DevHooks = if (builtin.mode == .Debug)
    @import("tools/dev_probe.zig")
else
    struct {
        /// Minimal stub implementation for non-debug builds.
        /// Returns a static message indicating development hooks are disabled.
        pub fn banner() []const u8 {
            return "dev hooks disabled";
        }
    };

/// Entry point demonstrating module discovery and conditional feature detection.
/// This function showcases:
/// 1. The new Zig 0.15.2 buffered writer API for stdout
/// 2. Compile-time conditional imports (DevHooks)
/// 3. Runtime introspection using @hasDecl to probe for optional functions
pub fn main() !void {
    // Create a stack-allocated buffer for stdout operations
    var stdout_buffer: [512]u8 = undefined;
    
    // Initialize a file writer with our buffer. This is part of the Zig 0.15.2
    // I/O revamp where writers now require explicit buffer management.
    var file_writer = std.fs.File.stdout().writer(&stdout_buffer);
    
    // Obtain the generic writer interface for formatted output
    const stdout = &file_writer.interface;

    // Report the current build mode (Debug, ReleaseSafe, ReleaseFast, ReleaseSmall)
    try stdout.print("discovery mode: {s}\n", .{@tagName(builtin.mode)});
    
    // Call the always-available banner() function from DevHooks.
    // The implementation varies based on whether we're in Debug mode or not.
    try stdout.print("dev hooks: {s}\n", .{DevHooks.banner()});

    // Use @hasDecl to check if the buildSession() function exists in DevHooks.
    // This demonstrates runtime discovery of optional capabilities without
    // requiring all implementations to provide every function.
    if (@hasDecl(DevHooks, "buildSession")) {
        // buildSession() is only available in the full dev_probe module (Debug builds)
        try stdout.print("built with zig {s}\n", .{DevHooks.buildSession()});
    } else {
        // In release builds, the stub DevHooks doesn't provide buildSession()
        try stdout.print("no buildSession() exported\n", .{});
    }

    // Flush the buffered output to ensure all content is written to stdout
    try stdout.flush();
}
