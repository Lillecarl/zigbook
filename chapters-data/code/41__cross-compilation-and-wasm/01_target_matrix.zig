// Import standard library for target querying and printing
const std = @import("std");
// Import builtin module to access compile-time host target information
const builtin = @import("builtin");

/// Entry point that demonstrates target discovery and cross-platform metadata inspection.
/// This example shows how to introspect both the host compilation target and parse
/// hypothetical cross-compilation targets without actually building for them.
pub fn main() void {
    // Print the host target triple (architecture-OS-ABI) by accessing builtin.target
    // This shows the platform Zig is currently compiling for
    std.debug.print(
        "host triple: {s}-{s}-{s}\n",
        .{
            @tagName(builtin.target.cpu.arch),
            @tagName(builtin.target.os.tag),
            @tagName(builtin.target.abi),
        },
    );

    // Display the pointer width for the host target
    // @bitSizeOf(usize) returns the size in bits of a pointer on the current platform
    std.debug.print("pointer width: {d} bits\n", .{@bitSizeOf(usize)});

    // Parse a WASI target query from a target triple string
    // This demonstrates how to inspect cross-compilation targets programmatically
    const wasm_query = std.Target.Query.parse(.{ .arch_os_abi = "wasm32-wasi" }) catch unreachable;
    describeQuery("wasm32-wasi", wasm_query);

    // Parse a Windows target query to show another cross-compilation scenario
    // The triple format follows: architecture-OS-ABI
    const windows_query = std.Target.Query.parse(.{ .arch_os_abi = "x86_64-windows-gnu" }) catch unreachable;
    describeQuery("x86_64-windows-gnu", windows_query);

    // Print whether the host target is configured for single-threaded execution
    // This compile-time constant affects runtime library behavior
    std.debug.print("single-threaded: {}\n", .{builtin.single_threaded});
}

/// Prints the resolved architecture, OS, and ABI for a given target query.
/// This helper demonstrates how to extract and display target metadata, using
/// the host target as a fallback when the query doesn't specify certain fields.
fn describeQuery(label: []const u8, query: std.Target.Query) void {
    std.debug.print(
        "query {s}: arch={s} os={s} abi={s}\n",
        .{
            label,
            // Fall back to host architecture if query doesn't specify one
            @tagName((query.cpu_arch orelse builtin.target.cpu.arch)),
            // Fall back to host OS if query doesn't specify one
            @tagName((query.os_tag orelse builtin.target.os.tag)),
            // Fall back to host ABI if query doesn't specify one
            @tagName((query.abi orelse builtin.target.abi)),
        },
    );
}
