const std = @import("std");

// Chapter 7 – Safe File Copier (atomic via std.fs.Dir.copyFile)
//
// A minimal, safe-by-default CLI that refuses to clobber an existing
// destination unless --force is provided. Uses std.fs.Dir.copyFile,
// which writes to a temporary file and atomically renames it into place.
//
// Usage:
//   zig run safe_copy.zig -- <src> <dst>
//   zig run safe_copy.zig -- --force <src> <dst>

const Cli = struct {
    force: bool = false,
    src: []const u8 = &[_]u8{},
    dst: []const u8 = &[_]u8{},
};

fn printUsage() void {
    std.debug.print("usage: safe-copy [--force] <source> <dest>\n", .{});
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

    // Validate that source exists and is a regular file.
    var src_file = cwd.openFile(cli.src, .{ .mode = .read_only }) catch {
        std.debug.print("error: unable to open source '{s}'\n", .{cli.src});
        std.process.exit(1);
    };
    defer src_file.close();

    const st = try src_file.stat();
    if (st.kind != .file) {
        std.debug.print("error: source is not a regular file\n", .{});
        std.process.exit(1);
    }

    // Respect safe-by-default semantics: refuse to overwrite unless --force.
    const dest_exists = blk: {
        _ = cwd.statFile(cli.dst) catch |err| switch (err) {
            error.FileNotFound => break :blk false,
            else => |e| return e,
        };
        break :blk true;
    };
    if (dest_exists and !cli.force) {
        std.debug.print("error: destination exists; pass --force to overwrite\n", .{});
        std.process.exit(2);
    }

    // Perform an atomic copy preserving mode by default. On success, there is
    // intentionally no output to keep pipelines quiet and scripting-friendly.
    cwd.copyFile(cli.src, cwd, cli.dst, .{ .override_mode = null }) catch |err| {
        std.debug.print("error: copy failed ({s})\n", .{@errorName(err)});
        std.process.exit(1);
    };
}
