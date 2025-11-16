
// Import standard library for debug printing capabilities
const std = @import("std");
// Import builtin module to access compile-time target information
const builtin = @import("builtin");

/// Prints a stage name to stderr for tracking execution flow.
/// This helper function demonstrates debug output in cross-platform contexts.
fn stage(name: []const u8) void {
    std.debug.print("stage: {s}\n", .{name});
}

/// Demonstrates conditional compilation based on target OS.
/// This example shows how Zig code can branch at compile-time depending on
/// whether it's compiled for WASI (WebAssembly System Interface) or native platforms.
/// The execution flow changes based on the target, illustrating cross-compilation capabilities.
pub fn main() void {
    // Simulate initial argument parsing stage
    stage("parse-args");
    // Simulate payload rendering stage
    stage("render-payload");

    // Compile-time branch: different entry points for WASI vs native targets
    // This demonstrates how Zig handles platform-specific code paths
    if (builtin.target.os.tag == .wasi) {
        stage("wasi-entry");
    } else {
        stage("native-entry");
    }

    // Print the actual OS tag name for the compilation target
    // @tagName converts the enum value to its string representation
    stage(@tagName(builtin.target.os.tag));
}
