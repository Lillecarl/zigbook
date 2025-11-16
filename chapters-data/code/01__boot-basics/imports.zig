// File: chapters-data/code/01__boot-basics/imports.zig

// Import the standard library for I/O, memory management, and core utilities
const std = @import("std");
// Import builtin to access compile-time information about the build environment
const builtin = @import("builtin");
// Import root to access declarations from the root source file
// In this case, we reference app_name which is defined in this file
const root = @import("root");

// Public constant that can be accessed by other modules importing this file
pub const app_name = "Boot Basics Tour";

// Main entry point of the program
// Returns an error union to propagate any I/O errors during execution
pub fn main() !void {
    // Allocate a fixed-size buffer on the stack for stdout operations
    // This buffer batches write operations to reduce syscalls
    var stdout_buffer: [256]u8 = undefined;
    // Create a buffered writer wrapping stdout
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    // Get the generic writer interface for polymorphic I/O operations
    const stdout = &stdout_writer.interface;

    // Print the application name by referencing the root module's declaration
    // Demonstrates how @import("root") allows access to the entry file's public declarations
    try stdout.print("app: {s}\n", .{root.app_name});
    
    // Print the optimization mode (Debug, ReleaseSafe, ReleaseFast, or ReleaseSmall)
    // @tagName converts the enum value to its string representation
    try stdout.print("optimize mode: {s}\n", .{@tagName(builtin.mode)});
    
    // Print the target triple showing CPU architecture, OS, and ABI
    // Each component is extracted from builtin.target and converted to a string
    try stdout.print(
        "target: {s}-{s}-{s}\n",
        .{
            @tagName(builtin.target.cpu.arch),
            @tagName(builtin.target.os.tag),
            @tagName(builtin.target.abi),
        },
    );
    
    // Flush the buffer to ensure all accumulated output is written to stdout
    try stdout.flush();
}
