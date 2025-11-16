// Import the standard library for I/O and basic functionality
const std = @import("std");
// Import a custom module from the project to access build configuration utilities
const config = @import("build_config.zig");
// Import a nested module demonstrating hierarchical module organization
// This path uses a directory structure: service/metrics.zig
const metrics = @import("service/metrics.zig");

/// Version string exported by the root module.
/// This demonstrates how the root module can expose public constants
/// that are accessible to other modules via @import("root").
pub const Version = "0.15.2";

/// Feature flags exported by the root module.
/// This array of string literals showcases a typical pattern for documenting
/// and advertising capabilities or experimental features in a Zig project.
pub const Features = [_][]const u8{
    "root-module-export",
    "builtin-introspection",
    "module-catalogue",
};

/// Entry point for the module graph report utility.
/// Demonstrates a practical use case for @import: composing functionality
/// from multiple modules (std, custom build_config, nested service/metrics)
/// and orchestrating their output to produce a unified report.
pub fn main() !void {
    // Allocate a buffer for stdout buffering to reduce system calls
    var stdout_buffer: [1024]u8 = undefined;
    // Create a buffered writer for stdout to improve I/O performance
    var file_writer = std.fs.File.stdout().writer(&stdout_buffer);
    // Obtain the generic writer interface for formatted output
    const stdout = &file_writer.interface;

    // Print a header to introduce the report
    try stdout.print("== Module graph walkthrough ==\n", .{});
    
    // Display the version constant defined in this root module
    // This shows how modules can export and reference their own public declarations
    try stdout.print("root.Version -> {s}\n", .{Version});

    // Invoke a function from the imported build_config module
    // This demonstrates cross-module function calls and how modules
    // encapsulate and expose behavior through their public API
    try config.printSummary(stdout);
    
    // Invoke a function from the nested metrics module
    // This illustrates hierarchical module organization and the ability
    // to compose deeply nested modules into a coherent application
    try metrics.printCatalog(stdout);

    // Flush the buffered writer to ensure all output is written to stdout
    try stdout.flush();
}
