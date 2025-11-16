const std = @import("std");

/// Returns a reference to a buffered stdout writer.
/// The buffer and writer are stored in a private struct to persist across calls.
fn stdout() *std.Io.Writer {
    const g = struct {
        // Static buffer for stdout writes—survives function returns
        var buf: [4096]u8 = undefined;
        // Writer wraps stdout with the buffer; created once
        var w = std.fs.File.stdout().writer(&buf);
    };
    // Return pointer to the writer's generic interface
    return &g.w.interface;
}

/// Counts the number of set bits (1s) in a single byte using bit manipulation.
/// Uses a well-known parallel popcount algorithm that avoids branches.
fn popcountByte(x: u8) u8 {
    var v = x;
    // Step 1: Count bits in pairs (2-bit groups)
    // Subtracts neighbor bit from each 2-bit group to get counts 0-2
    v = v - ((v >> 1) & 0x55);
    // Step 2: Count bits in nibbles (4-bit groups)
    // Adds adjacent 2-bit counts to get nibble counts 0-4
    v = (v & 0x33) + ((v >> 2) & 0x33);
    // Step 3: Combine nibbles and mask low 4 bits (result 0-8)
    // Adding the two nibbles gives total count, truncate to u8
    return @truncate(((v + (v >> 4)) & 0x0F));
}

/// Builds a 256-entry lookup table at compile time.
/// Each entry [i] holds the number of set bits in byte value i.
fn buildPopcountTable() [256]u8 {
    // Initialize table with zeros (all 256 entries)
    var t: [256]u8 = .{0} ** 256;
    // Compile-time loop index (required for inline while)
    comptime var i: usize = 0;
    // Unrolled loop: compute popcount for each possible byte value
    inline while (i < 256) : (i += 1) {
        // Store the bit count for byte value i
        t[i] = popcountByte(@intCast(i));
    }
    // Return the fully populated table as a compile-time constant
    return t;
}

pub fn main() !void {
    // Acquire the buffered stdout writer
    const out = stdout();
    
    // Generate the popcount lookup table at compile time
    const T = buildPopcountTable();
    
    // Test data: array of bytes to analyze
    const bytes = [_]u8{ 0x00, 0x0F, 0xF0, 0xAA, 0xFF };
    
    // Accumulator for total set bits across all test bytes
    var sum: usize = 0;
    
    // Sum up set bits by indexing into the precomputed table
    for (bytes) |b| sum += T[b];
    
    // Print label for the output
    try out.print("bytes: ", .{});
    
    // Print each byte in hex format with spacing
    for (bytes, 0..) |b, idx| {
        // Add space separator between bytes (not before first)
        if (idx != 0) try out.print(" ", .{});
        // Format as 0x-prefixed 2-digit hex (e.g., 0x0F)
        try out.print("0x{X:0>2}", .{b});
    }
    
    // Print the final sum of all set bits
    try out.print(" -> total set bits = {}\n", .{sum});
    
    // Flush the buffered writer to ensure all output appears
    try out.flush();
}
