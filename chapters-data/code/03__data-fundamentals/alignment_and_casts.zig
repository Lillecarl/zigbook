const std = @import("std");

/// Demonstrates memory alignment concepts and various type casting operations in Zig.
/// This example covers:
/// - Memory alignment guarantees with align() attribute
/// - Pointer casting with alignment adjustments using @alignCast
/// - Type punning with @ptrCast for reinterpreting memory
/// - Bitwise reinterpretation with @bitCast
/// - Truncating integers with @truncate
/// - Widening integers with @intCast
/// - Floating-point precision conversion with @floatCast
pub fn main() !void {
    // Create a byte array aligned to u64 boundary, initialized with little-endian bytes
    // representing 0x11223344 in the first 4 bytes
    var raw align(@alignOf(u64)) = [_]u8{ 0x44, 0x33, 0x22, 0x11, 0, 0, 0, 0 };

    // Get a pointer to the first byte with explicit u64 alignment
    const base: *align(@alignOf(u64)) u8 = &raw[0];
    
    // Adjust alignment constraint from u64 to u32 using @alignCast
    // This is safe because u64 alignment (8 bytes) satisfies u32 alignment (4 bytes)
    const aligned_bytes = @as(*align(@alignOf(u32)) const u8, @alignCast(base));
    
    // Reinterpret the byte pointer as a u32 pointer to read 4 bytes as a single integer
    const word_ptr = @as(*const u32, @ptrCast(aligned_bytes));
    
    // Dereference to get the 32-bit value (little-endian: 0x11223344)
    const number = word_ptr.*;
    std.debug.print("32-bit value = 0x{X:0>8}\n", .{number});

    // Alternative approach: directly reinterpret the first 4 bytes using @bitCast
    // This creates a copy and doesn't require pointer manipulation
    const from_bytes = @as(u32, @bitCast(raw[0..4].*));
    std.debug.print("bitcast copy = 0x{X:0>8}\n", .{from_bytes});

    // Demonstrate @truncate: extract the least significant 8 bits (0x44)
    const small: u8 = @as(u8, @truncate(number));
    
    // Demonstrate @intCast: widen unsigned u32 to signed i64 without data loss
    const widened: i64 = @as(i64, @intCast(number));
    std.debug.print("truncate -> 0x{X:0>2}, widen -> {d}\n", .{ small, widened });

    // Demonstrate @floatCast: reduce f64 precision to f32
    // May result in precision loss for values that cannot be exactly represented in f32
    const ratio64: f64 = 1.875;
    const ratio32: f32 = @as(f32, @floatCast(ratio64));
    std.debug.print("floatCast ratio -> {}\n", .{ratio32});
}
