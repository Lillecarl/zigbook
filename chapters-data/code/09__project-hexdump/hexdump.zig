const std = @import("std");

// Chapter 9 – Project: Hexdump
//
// A small, alignment-aware hexdump that prints:
//   OFFSET: 16 hex bytes (grouped 8|8)  ASCII
// Default width is 16 bytes per line; override with --width N (4..32).
//
// Usage:
//   zig run hexdump.zig -- <path>
//   zig run hexdump.zig -- --width 8 <path>

const Cli = struct {
    width: usize = 16,
    path: []const u8 = &[_]u8{},
};

fn printUsage() void {
    std.debug.print("usage: hexdump [--width N] <path>\n", .{});
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
    while (i + 1 < args.len and std.mem.eql(u8, args[i], "--width")) : (i += 2) {
        const val = args[i + 1];
        cli.width = std.fmt.parseInt(usize, val, 10) catch {
            std.debug.print("error: invalid width '{s}'\n", .{val});
            std.process.exit(2);
        };
        if (cli.width < 4 or cli.width > 32) {
            std.debug.print("error: width must be between 4 and 32\n", .{});
            std.process.exit(2);
        }
    }

    if (i >= args.len) {
        std.debug.print("error: expected <path>\n", .{});
        printUsage();
        std.process.exit(2);
    }

    // Duplicate the path so it remains valid after freeing args.
    cli.path = try allocator.dupe(u8, args[i]);
    return cli;
}

fn isPrintable(c: u8) bool {
    // Printable ASCII (space through tilde)
    return c >= 0x20 and c <= 0x7E;
}

fn dumpLine(stdout: *std.Io.Writer, offset: usize, bytes: []const u8, width: usize) !void {
    // OFFSET (8 hex digits), colon and space
    try stdout.print("{X:0>8}: ", .{offset});

    // Hex bytes with grouping at 8
    var i: usize = 0;
    while (i < width) : (i += 1) {
        if (i < bytes.len) {
            try stdout.print("{X:0>2} ", .{bytes[i]});
        } else {
            // pad absent bytes to keep ASCII column aligned
            try stdout.print("   ", .{});
        }
        if (i + 1 == width / 2) {
            try stdout.print(" ", .{}); // extra gap between 8|8
        }
    }

    // Two spaces before ASCII gutter
    try stdout.print("  ", .{});

    i = 0;
    while (i < width) : (i += 1) {
        if (i < bytes.len) {
            const ch: u8 = if (isPrintable(bytes[i])) bytes[i] else '.';
            try stdout.print("{c}", .{ch});
        } else {
            try stdout.print(" ", .{});
        }
    }
    try stdout.print("\n", .{});
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const cli = try parseArgs(allocator);

    var file = std.fs.cwd().openFile(cli.path, .{ .mode = .read_only }) catch {
        std.debug.print("error: unable to open '{s}'\n", .{cli.path});
        std.process.exit(1);
    };
    defer file.close();

    // Buffered stdout using the modern File.Writer + Io.Writer interface.
    var out_buf: [16 * 1024]u8 = undefined;
    var file_writer = std.fs.File.writer(std.fs.File.stdout(), &out_buf);
    const stdout = &file_writer.interface;

    var offset: usize = 0;
    var carry: [64]u8 = undefined; // enough for max width 32
    var carry_len: usize = 0;

    var buf: [64 * 1024]u8 = undefined;
    while (true) {
        const n = try file.read(buf[0..]);
        if (n == 0 and carry_len == 0) break;

        var idx: usize = 0;
        while (idx < n) {
            // fill a line from carry + buffer bytes
            const need = cli.width - carry_len;
            const take = @min(need, n - idx);
            @memcpy(carry[carry_len .. carry_len + take], buf[idx .. idx + take]);
            carry_len += take;
            idx += take;

            if (carry_len == cli.width) {
                try dumpLine(stdout, offset, carry[0..carry_len], cli.width);
                offset += carry_len;
                carry_len = 0;
            }
        }

        if (n == 0 and carry_len > 0) {
            try dumpLine(stdout, offset, carry[0..carry_len], cli.width);
            offset += carry_len;
            carry_len = 0;
        }
    }
    try file_writer.end();
}
