
// This program demonstrates how compile-time configuration affects binary size
// by conditionally enabling debug tracing based on the build mode.
const std = @import("std");
const builtin = @import("builtin");

// Compile-time flag that enables tracing only in Debug mode
// This demonstrates how dead code elimination works in release builds
const enable_tracing = builtin.mode == .Debug;

// Computes a FNV-1a hash for a given word
// FNV-1a is a fast, non-cryptographic hash function
// @param word: The input byte slice to hash
// @return: A 64-bit hash value
fn checksumWord(word: []const u8) u64 {
    // FNV-1a 64-bit offset basis
    var state: u64 = 0xcbf29ce484222325;
    
    // Process each byte of the input
    for (word) |byte| {
        // XOR with the current byte
        state ^= byte;
        // Multiply by FNV-1a 64-bit prime (with wrapping multiplication)
        state = state *% 0x100000001b3;
    }
    return state;
}

pub fn main() !void {
    // Sample word list to demonstrate the checksum functionality
    const words = [_][]const u8{ "profiling", "optimization", "hardening", "zig" };
    
    // Accumulator for combining all word checksums
    var digest: u64 = 0;
    
    // Process each word and combine their checksums
    for (words) |word| {
        const word_sum = checksumWord(word);
        // Combine checksums using XOR
        digest ^= word_sum;
        
        // Conditional tracing that will be compiled out in release builds
        // This demonstrates how build mode affects binary size
        if (enable_tracing) {
            std.debug.print("trace: {s} -> {x}\n", .{ word, word_sum });
        }
    }

    // Output the final result along with the current build mode
    // Shows how the same code behaves differently based on compilation settings
    std.debug.print(
        "mode={s} digest={x}\n",
        .{
            @tagName(builtin.mode),
            digest,
        },
    );
}
