const std = @import("std");

// Demonstrate std.Io.Writer.Discarding to ignore outputs (useful in benchmarks)
pub fn main() !void {
    var buf: [32]u8 = undefined;
    var w: std.Io.Writer = .fixed(&buf);

    try w.print("Ephemeral output: {d}\n", .{999});

    // Discard content by consuming buffered bytes
    _ = std.Io.Writer.consumeAll(&w);

    // Show buffer now empty
    std.debug.print("Buffer after consumeAll length: {d}\n", .{w.buffered().len});
}
