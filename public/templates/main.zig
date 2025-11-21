//! File: main.zig
//! https://run.zigbook.net/ 
//! Created by Zigbook (https://zigbook.net).
//! Zig version: 0.15.0

// This example shows how to use Zig's standard library to print messages to the console.

/// Imports the Zig standard library, providing access to core functionality
/// This import is typically required in most Zig programs to access fundamental utilities.
const std = @import("std");

/// A constant alias for `std.debug.print`, used for printing debug messages to stderr.
const print = std.debug.print;

/// The main entry point of the program.
pub fn main() !void {

    // Print a welcome message to stdout using `a writeAll
    try std.fs.File.stdout().writeAll("Hello World!\n");
    try std.fs.File.stdout().writeAll("\n");
    try std.fs.File.stdout().writeAll("Welcome to Zigbook!\n");
    try std.fs.File.stdout().writeAll("This is a simple Zig program running in the Zig playground.\n");
    try std.fs.File.stdout().writeAll("\n");

    print("Don't forget to join the new Zig community!\n", .{});
    print("Visit https://forums.zigbook.net for more information.\n", .{});
}

// Don't forget to join the new Zig community!
// Visit https://forums.zigbook.net for more information.
