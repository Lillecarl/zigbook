const std = @import("std");
const builtin = @import("builtin");

pub fn main() !void {
    // Emit a quick note to stderr using the convenience helper.
    std.debug.print("[stderr] staged diagnostics\n", .{});

    // Lock stderr explicitly for a multi-line message.
    {
        const writer = std.debug.lockStderrWriter(&.{});
        defer std.debug.unlockStderrWriter();
        writer.writeAll("[stderr] stack capture incoming\n") catch {};
    }

    var stdout_buffer: [256]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const out = &stdout_writer.interface;

    // Capture a trimmed stack trace without printing raw addresses.
    var frame_storage: [8]usize = undefined;
    var trace = std.builtin.StackTrace{
        .index = 0,
        .instruction_addresses = frame_storage[0..],
    };
    std.debug.captureStackTrace(null, &trace);
    try out.print("frames captured -> {d}\n", .{trace.index});

    // Guard a sentinel with the debug assertions that participate in safety mode.
    const marker = "panic probe";
    std.debug.assert(marker.len == 11);

    var buffer = [_]u8{ 0x41, 0x42, 0x43, 0x44 };
    std.debug.assertReadable(buffer[0..]);
    std.debug.assertAligned(&buffer, .@"1");

    // Report build configuration facts gathered from std.debug.
    try out.print(
        "runtime_safety -> {s}\n",
        .{if (std.debug.runtime_safety) "enabled" else "disabled"},
    );
    try out.print(
        "optimize_mode -> {s}\n",
        .{@tagName(builtin.mode)},
    );

    // Show manual formatting against a fixed buffer, useful when stderr is locked.
    var scratch: [96]u8 = undefined;
    var stream = std.io.fixedBufferStream(&scratch);
    try stream.writer().print("captured slice -> {s}\n", .{marker});
    try out.print("{s}", .{stream.getWritten()});
    try out.flush();
}
