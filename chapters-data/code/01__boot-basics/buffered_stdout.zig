// File: chapters-data/code/01__boot-basics/buffered_stdout.zig
const std = @import("std");

pub fn main() !void {
    // Allocate a 256-byte buffer on the stack for output batching
    // This buffer accumulates write operations to minimize syscalls
    var stdout_buffer: [256]u8 = undefined;
    
    // Create a buffered writer wrapping stdout
    // The writer batches output into stdout_buffer before making syscalls
    var writer_state = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &writer_state.interface;

    // These print calls write to the buffer, not directly to the terminal
    // No syscalls occur yet—data accumulates in stdout_buffer
    try stdout.print("Buffering saves syscalls.\n", .{});
    try stdout.print("Flush once at the end.\n", .{});
    
    // Explicitly flush the buffer to write all accumulated data at once
    // This triggers a single syscall instead of one per print operation
    try stdout.flush();
}
