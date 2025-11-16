
// Import the standard library for basic functionality
const std = @import("std");
// Import the root module to access project-specific declarations
const root = @import("root");
// Import the builtin module for compile-time build information
const builtin = @import("builtin");

/// Prints a summary of the current build configuration to the provided writer.
/// This function demonstrates how to access and use the `builtin` and `root` modules
/// to inspect compilation mode, target architecture, OS, and custom features.
///
/// The output format is:
/// - First line: "mode=<mode> target=<arch>-<os>"
/// - Second line: "features: <feature1> <feature2> ..."
pub fn printSummary(writer: anytype) !void {
    // Print the build mode (Debug, ReleaseSafe, etc.) and target platform information
    try writer.print(
        "mode={s} target={s}-{s}\n",
        .{
            @tagName(builtin.mode),
            @tagName(builtin.target.cpu.arch),
            @tagName(builtin.target.os.tag),
        },
    );
    
    // Print the custom features list defined in the root module
    try writer.print("features:", .{});
    // Iterate through each feature and print it
    for (root.Features) |feat| {
        try writer.print(" {s}", .{feat});
    }
    try writer.print("\n", .{});
}
