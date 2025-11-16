// This program demonstrates how to use custom modules in Zig's build system.
// It imports a local "math" module and uses its functions to perform basic arithmetic operations.

// Import the standard library for debug printing capabilities
const std = @import("std");
// Import the custom math module which provides arithmetic operations
const math = @import("math");

// Main entry point demonstrating module usage with basic arithmetic
pub fn main() !void {
    // Define two constant operands for demonstration
    const a = 10;
    const b = 20;
    
    // Print the result of addition using the imported math module
    std.debug.print("{d} + {d} = {d}\n", .{ a, b, math.add(a, b) });
    
    // Print the result of multiplication using the imported math module
    std.debug.print("{d} * {d} = {d}\n", .{ a, b, math.multiply(a, b) });
}
