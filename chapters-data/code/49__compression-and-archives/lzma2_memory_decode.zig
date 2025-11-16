const std = @import("std");

pub fn main() !void {
    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    const compressed = [_]u8{
        0x01, 0x00, 0x05, 0x48, 0x65, 0x6c, 0x6c, 0x6f, 0x0a, 0x02, 0x00, 0x06, 0x57, 0x6f,
        0x72, 0x6c, 0x64, 0x21, 0x0a, 0x00,
    };

    var stream = std.io.fixedBufferStream(&compressed);
    var collector = std.Io.Writer.Allocating.init(allocator);
    defer collector.deinit();

    try std.compress.lzma2.decompress(allocator, stream.reader(), &collector.writer);
    const decoded = collector.writer.buffer[0..collector.writer.end];

    try stdout.print("lzma2 decoded ({d} bytes):\n{s}\n", .{ decoded.len, decoded });
    try stdout.flush();
}
