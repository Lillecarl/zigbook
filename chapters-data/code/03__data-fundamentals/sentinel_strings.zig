const std = @import("std");

/// Demonstrates sentinel-terminated strings and arrays in Zig, including:
/// - Zero-terminated string literals ([:0]const u8)
/// - Many-item sentinel pointers ([*:0]const u8)
/// - Sentinel-terminated arrays ([N:0]T)
/// - Converting between sentinel slices and regular slices
/// - Mutation through sentinel pointers
pub fn main() !void {
    // String literals in Zig are sentinel-terminated by default with a zero byte
    // [:0]const u8 denotes a slice with a sentinel value of 0 at the end
    const literal: [:0]const u8 = "data fundamentals";
    
    // Convert the sentinel slice to a many-item sentinel pointer
    // [*:0]const u8 is compatible with C-style null-terminated strings
    const c_ptr: [*:0]const u8 = literal;
    
    // std.mem.span converts a sentinel-terminated pointer back to a slice
    // It scans until it finds the sentinel value (0) to determine the length
    const bytes = std.mem.span(c_ptr);
    std.debug.print("literal len={} contents=\"{s}\"\n", .{ bytes.len, bytes });

    // Declare a sentinel-terminated array with explicit size and sentinel value
    // [6:0]u8 means an array of 6 elements plus a sentinel 0 byte at position 6
    var label: [6:0]u8 = .{ 'l', 'a', 'b', 'e', 'l', 0 };
    
    // Create a mutable sentinel slice from the array
    // The [0.. :0] syntax creates a slice from index 0 to the end, with sentinel 0
    var sentinel_view: [:0]u8 = label[0.. :0];
    
    // Modify the first element through the sentinel slice
    sentinel_view[0] = 'L';

    // Create a regular (non-sentinel) slice from the first 4 elements
    // This drops the sentinel guarantees but provides a bounded slice
    const trimmed: []const u8 = sentinel_view[0..4];
    std.debug.print("trimmed slice len={} -> {s}\n", .{ trimmed.len, trimmed });

    // Convert the sentinel slice to a many-item sentinel pointer
    // This allows unchecked indexing while preserving sentinel information
    const tail: [*:0]u8 = sentinel_view;
    
    // Modify element at index 4 through the many-item sentinel pointer
    // No bounds checking occurs, but the sentinel guarantees remain valid
    tail[4] = 'X';

    // Demonstrate that mutations through the pointer affected the original array
    // std.mem.span uses the sentinel to reconstruct the full slice
    std.debug.print("full label after mutation: {s}\n", .{std.mem.span(tail)});
}
