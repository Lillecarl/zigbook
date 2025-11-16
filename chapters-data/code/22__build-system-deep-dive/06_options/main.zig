
// Import standard library for debug printing functionality
const std = @import("std");
// Import build-time configuration options defined in build.zig
const config = @import("config");

/// Entry point of the application demonstrating the use of build options.
/// This function showcases how to access and use configuration values that
/// are set during the build process through the Zig build system.
pub fn main() !void {
    // Display the application name from build configuration
    std.debug.print("Application: {s}\n", .{config.app_name});
    // Display the logging toggle status from build configuration
    std.debug.print("Logging enabled: {}\n", .{config.enable_logging});

    // Conditionally execute debug logging based on build-time configuration
    // This demonstrates compile-time branching using build options
    if (config.enable_logging) {
        std.debug.print("[DEBUG] This is a debug message\n", .{});
    }
}
