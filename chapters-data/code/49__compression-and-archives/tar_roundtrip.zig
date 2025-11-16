const std = @import("std");

pub fn main() !void {
    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    var archive_storage: [4096]u8 = undefined;
    var archive_writer = std.Io.Writer.fixed(&archive_storage);
    var tar_writer = std.tar.Writer{ .underlying_writer = &archive_writer };

    try tar_writer.writeDir("reports", .{ .mode = 0o755 });
    try tar_writer.writeFileBytes(
        "reports/summary.txt",
        "cpu=28%\nmem=512MiB\n",
        .{ .mode = 0o644 },
    );

    const archive = archive_writer.buffer[0..archive_writer.end];

    try stdout.print("tar archive is {d} bytes and holds:\n", .{archive.len});

    var source: std.Io.Reader = .fixed(archive);
    var name_buf: [std.fs.max_path_bytes]u8 = undefined;
    var link_buf: [std.fs.max_path_bytes]u8 = undefined;
    var iter = std.tar.Iterator.init(&source, .{
        .file_name_buffer = &name_buf,
        .link_name_buffer = &link_buf,
    });

    while (try iter.next()) |entry| {
        try stdout.print("- {s} ({s}, {d} bytes)\n", .{ entry.name, @tagName(entry.kind), entry.size });
        if (entry.kind == .file) {
            var file_buf: [128]u8 = undefined;
            var file_writer = std.Io.Writer.fixed(&file_buf);
            try iter.streamRemaining(entry, &file_writer);
            const written = file_writer.end;
            const payload = file_buf[0..written];
            try stdout.print("  contents: {s}\n", .{payload});
        }
    }

    try stdout.flush();
}
