const std = @import("std");

// Chapter 7 – Safe File Copier (manual streaming with errdefer cleanup)
//
// Demonstrates opening, reading, writing, and cleaning up safely using
// defer/errdefer. If the copy fails after destination creation, we remove
// the partial file so callers never observe a truncated artifact.
//
// Usage:
//   zig run copy_stream.zig -- <src> <dst>
//   zig run copy_stream.zig -- --force <src> <dst>

const Cli = struct {
    force: bool = false,
    src: []const u8 = &[_]u8{},
    dst: []const u8 = &[_]u8{},
};

fn printUsage() void {
    std.debug.print("usage: copy-stream [--force] <source> <dest>\n", .{});
}

fn parseArgs(allocator: std.mem.Allocator) !Cli {
    var cli: Cli = .{};
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len == 1 or (args.len == 2 and std.mem.eql(u8, args[1], "--help"))) {
        printUsage();
        std.process.exit(0);
    }

    var i: usize = 1;
    while (i < args.len and std.mem.startsWith(u8, args[i], "--")) : (i += 1) {
        const flag = args[i];
        if (std.mem.eql(u8, flag, "--force")) {
            cli.force = true;
        } else if (std.mem.eql(u8, flag, "--help")) {
            printUsage();
            std.process.exit(0);
        } else {
            std.debug.print("error: unknown flag '{s}'\n", .{flag});
            printUsage();
            std.process.exit(2);
        }
    }

    const remaining = args.len - i;
    if (remaining != 2) {
        std.debug.print("error: expected <source> and <dest>\n", .{});
        printUsage();
        std.process.exit(2);
    }

    // Duplicate paths so they remain valid after freeing args.
    cli.src = try allocator.dupe(u8, args[i]);
    cli.dst = try allocator.dupe(u8, args[i + 1]);
    return cli;
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const cli = try parseArgs(allocator);

    const cwd = std.fs.cwd();

    // Open source and inspect its metadata.
    var src = cwd.openFile(cli.src, .{ .mode = .read_only }) catch {
        std.debug.print("error: unable to open source '{s}'\n", .{cli.src});
        std.process.exit(1);
    };
    defer src.close();

    const st = try src.stat();
    if (st.kind != .file) {
        std.debug.print("error: source is not a regular file\n", .{});
        std.process.exit(1);
    }

    // Safe-by-default: refuse to overwrite unless --force.
    if (!cli.force) {
        const dest_exists = blk: {
            _ = cwd.statFile(cli.dst) catch |err| switch (err) {
                error.FileNotFound => break :blk false,
                else => |e| return e,
            };
            break :blk true;
        };
        if (dest_exists) {
            std.debug.print("error: destination exists; pass --force to overwrite\n", .{});
            std.process.exit(2);
        }
    }

    // Create destination with exclusive mode when not forcing overwrite.
    var dest = cwd.createFile(cli.dst, .{
        .read = false,
        .truncate = cli.force,
        .exclusive = !cli.force,
        .mode = st.mode,
    }) catch |err| switch (err) {
        error.PathAlreadyExists => {
            std.debug.print("error: destination exists; pass --force to overwrite\n", .{});
            std.process.exit(2);
        },
        else => |e| {
            std.debug.print("error: cannot create destination ({s})\n", .{@errorName(e)});
            std.process.exit(1);
        },
    };
    // Ensure closure and cleanup order: close first, then delete on error.
    defer dest.close();
    errdefer cwd.deleteFile(cli.dst) catch {};

    // Wire a Reader/Writer pair and copy using the Writer interface.
    var reader: std.fs.File.Reader = .initSize(src, &.{}, st.size);
    var write_buf: [64 * 1024]u8 = undefined; // buffered writes
    var writer = std.fs.File.writer(dest, &write_buf);

    _ = writer.interface.sendFileAll(&reader, .unlimited) catch |err| switch (err) {
        error.ReadFailed => return reader.err.?,
        error.WriteFailed => return writer.err.?,
    };

    // Flush buffered bytes and set the final file length.
    try writer.end();
}
