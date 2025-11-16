// Import the standard library for common utilities and types
const std = @import("std");
// Import builtin module to access compile-time information about the build
const builtin = @import("builtin");
// Import the overlay module by name as it will be registered via --dep/-M on the CLI
const overlay = @import("overlay");

/// Entry point for the package overlay demonstration program.
/// Demonstrates how to use the overlay_widget library to display package information
/// including build mode and target operating system details.
pub fn main() !void {
    // Allocate a fixed-size buffer on the stack for stdout operations
    // This avoids heap allocation for simple output scenarios
    var stdout_buffer: [512]u8 = undefined;
    // Create a buffered writer for stdout to improve performance by batching writes
    var file_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &file_writer.interface;

    // Populate package details structure with information about the current package
    // This includes compile-time information like optimization mode and target OS
    const details = overlay.PackageDetails{
        .package_name = "overlay",
        .role = "library package",
        // Extract the optimization mode name (e.g., Debug, ReleaseFast) at compile time
        .optimize_mode = @tagName(builtin.mode),
        // Extract the target OS name (e.g., linux, windows) at compile time
        .target_os = @tagName(builtin.target.os.tag),
    };

    // Render the package summary to stdout using the overlay library
    try overlay.renderSummary(stdout, details);
    // Ensure all buffered output is written to the terminal
    try stdout.flush();
}
