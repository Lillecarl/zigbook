// Main entry point demonstrating the factorial function from mylib.
// This example shows how to:
// - Import and use custom library modules
// - Call library functions with different input values
// - Display computed results using debug printing
const std = @import("std");
const mylib = @import("mylib");

pub fn main() !void {
    std.debug.print("5! = {d}\n", .{mylib.factorial(5)});
    std.debug.print("10! = {d}\n", .{mylib.factorial(10)});
}
