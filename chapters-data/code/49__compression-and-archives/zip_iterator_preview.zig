const std = @import("std");

pub fn main() !void {
    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    const archive_bytes = @embedFile("demo.zip");

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    var zip_file = try tmp.dir.createFile("demo.zip", .{ .read = true, .truncate = true });
    defer {
        zip_file.close();
        tmp.dir.deleteFile("demo.zip") catch {};
    }

    try zip_file.writeAll(archive_bytes);
    try zip_file.seekTo(0);

    var read_buffer: [4096]u8 = undefined;
    var archive_reader = zip_file.reader(&read_buffer);
    var iter = try std.zip.Iterator.init(&archive_reader);

    var name_buf: [std.fs.max_path_bytes]u8 = undefined;

    try stdout.print("zip archive contains:\n", .{});

    while (try iter.next()) |entry| {
        try entry.extract(&archive_reader, .{}, &name_buf, tmp.dir);
        const name = name_buf[0..entry.filename_len];
        try stdout.print(
            "- {s} ({s}, {d} bytes)\n",
            .{ name, @tagName(entry.compression_method), entry.uncompressed_size },
        );

        if (name.len != 0 and name[name.len - 1] == '/') continue;

        var file = try tmp.dir.openFile(name, .{});
        defer file.close();
        const info = try file.stat();
        const size: usize = @intCast(info.size);
        const contents = try allocator.alloc(u8, size);
        defer allocator.free(contents);
        const read_len = try file.readAll(contents);
        const slice = contents[0..read_len];

        if (std.mem.endsWith(u8, name, ".txt")) {
            try stdout.print("  text: {s}\n", .{slice});
        } else {
            try stdout.print("  bytes:", .{});
            for (slice, 0..) |byte, idx| {
                const prefix = if (idx % 16 == 0) "\n    " else " ";
                try stdout.print("{s}{X:0>2}", .{ prefix, byte });
            }
            try stdout.print("\n", .{});
        }
    }

    try stdout.flush();
}
