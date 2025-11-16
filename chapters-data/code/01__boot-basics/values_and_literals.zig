// File: chapters-data/code/01__boot-basics/values_and_literals.zig
const std = @import("std");

pub fn main() !void {
    // Declare a mutable variable with explicit type annotation
    // u32 is an unsigned 32-bit integer, initialized to 1
    var counter: u32 = 1;
    
    // Declare an immutable constant with inferred type (comptime_int)
    // The compiler infers the type from the literal value 2
    const increment = 2;
    
    // Declare a constant with explicit floating-point type
    // f64 is a 64-bit floating-point number
    const ratio: f64 = 0.5;
    
    // Boolean constant with inferred type
    // Demonstrates Zig's type inference for simple literals
    const flag = true;
    
    // Character literal representing a newline
    // Single-byte characters are u8 values in Zig
    const newline: u8 = '\n';
    
    // The unit type value, analogous to () in other languages
    // Represents "no value" or "nothing" explicitly
    const unit_value = void{};

    // Mutate the counter by adding the increment
    // Only var declarations can be modified
    counter += increment;

    // Print formatted output showing different value types
    // {} is a generic format specifier that works with any type
    std.debug.print("counter={} ratio={} safety={}\n", .{ counter, ratio, flag });
    
    // Cast the newline byte to u32 for display as its ASCII decimal value
    // @as performs explicit type coercion
    std.debug.print("newline byte={} (ASCII)\n", .{@as(u32, newline)});
    
    // Use compile-time reflection to print the type name of unit_value
    // @TypeOf gets the type, @typeName converts it to a string
    std.debug.print("unit literal has type {s}\n", .{@typeName(@TypeOf(unit_value))});
}
