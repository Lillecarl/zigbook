
// Import the standard library for printing capabilities
const std = @import("std");

// External function declaration: doubles the input integer
// This function is defined in a separate library/object file
extern fn util_double(x: i32) i32;

// External function declaration: squares the input integer
// This function is defined in a separate library/object file
extern fn util_square(x: i32) i32;

// Main entry point demonstrating library linking
// Calls external utility functions to show build system integration
pub fn main() !void {
    // Test value for demonstrating the external functions
    const x: i32 = 7;
    
    // Print the result of doubling x using the external function
    std.debug.print("double({d}) = {d}\n", .{ x, util_double(x) });
    
    // Print the result of squaring x using the external function
    std.debug.print("square({d}) = {d}\n", .{ x, util_square(x) });
}
