// Import the Zig standard library for basic functionality
const std = @import("std");

// Import C header file using @cImport to interoperate with C code
// This creates a namespace 'c' containing all declarations from "bridge.h"
const c = @cImport({
    @cInclude("bridge.h");
});

// Export a Zig function with C calling convention so it can be called from C
// The 'export' keyword makes this function visible to C code
// callconv(.c) ensures it uses the platform's C ABI for parameter passing and stack management
export fn zig_add(a: c_int, b: c_int) callconv(.c) c_int {
    return a + b;
}

pub fn main() !void {
    // Create a fixed-size buffer for stdout to avoid heap allocations
    var stdout_buffer: [128]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const out = &stdout_writer.interface;

    // Call C function c_mul from the imported header
    // This demonstrates Zig calling into C code seamlessly
    const mul = c.c_mul(6, 7);
    
    // Call C function that internally calls back into our exported zig_add function
    // This demonstrates the round-trip: Zig -> C -> Zig
    const sum = c.call_zig_add(19, 23);

    // Print the result from the C multiplication function
    try out.print("c_mul(6, 7) = {d}\n", .{mul});
    
    // Print the result from the C function that called our Zig function
    try out.print("call_zig_add(19, 23) = {d}\n", .{sum});
    
    // Flush the buffered output to ensure all data is written
    try out.flush();
}
