const std = @import("std");

const whitespace = " \t\r";

pub fn main() !void {
    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const out = &stdout_writer.interface;

    const config =
        \\# site roots and toggles
        \\root = /srv/www
        \\root=/srv/cache
        \\mode = fast-render
        \\log-level = warn
        \\extra-paths = :/opt/tools:/opt/tools/bin:
        \\
        \\# trailing noise we should ignore
        \\:
    ;

    var root_storage: [6][]const u8 = undefined;
    var root_count: usize = 0;
    var extra_storage: [8][]const u8 = undefined;
    var extra_count: usize = 0;
    var mode_buffer: [32]u8 = undefined;
    var normalized_mode: []const u8 = "slow";
    var log_level: []const u8 = "info";

    var lines = std.mem.tokenizeScalar(u8, config, '\n');
    while (lines.next()) |line| {
        const trimmed = std.mem.trim(u8, line, whitespace);
        if (trimmed.len == 0 or std.mem.startsWith(u8, trimmed, "#")) continue;

        const eq_index = std.mem.indexOfScalar(u8, trimmed, '=') orelse continue;

        const key = std.mem.trim(u8, trimmed[0..eq_index], whitespace);
        const value = std.mem.trim(u8, trimmed[eq_index + 1 ..], whitespace);

        if (std.mem.eql(u8, key, "root")) {
            if (root_count < root_storage.len) {
                root_storage[root_count] = value;
                root_count += 1;
            }
        } else if (std.mem.eql(u8, key, "mode")) {
            if (value.len <= mode_buffer.len) {
                std.mem.copyForwards(u8, mode_buffer[0..value.len], value);
                const mode_view = mode_buffer[0..value.len];
                std.mem.replaceScalar(u8, mode_view, '-', '_');
                normalized_mode = mode_view;
            }
        } else if (std.mem.eql(u8, key, "log-level")) {
            log_level = value;
        } else if (std.mem.eql(u8, key, "extra-paths")) {
            var paths = std.mem.splitScalar(u8, value, ':');
            while (paths.next()) |segment| {
                const cleaned = std.mem.trim(u8, segment, whitespace);
                if (cleaned.len == 0) continue;
                if (extra_count < extra_storage.len) {
                    extra_storage[extra_count] = cleaned;
                    extra_count += 1;
                }
            }
        }
    }

    var extras_join_buffer: [256]u8 = undefined;
    var extras_allocator = std.heap.FixedBufferAllocator.init(&extras_join_buffer);
    var extras_joined_slice: []u8 = &.{};
    if (extra_count != 0) {
        extras_joined_slice = try std.mem.join(extras_allocator.allocator(), ", ", extra_storage[0..extra_count]);
    }
    const extras_joined: []const u8 = if (extra_count == 0) "(none)" else extras_joined_slice;

    try out.print("normalized mode -> {s}\n", .{normalized_mode});
    try out.print("log level -> {s}\n", .{log_level});
    try out.print("roots ({d})\n", .{root_count});
    for (root_storage[0..root_count], 0..) |root, idx| {
        try out.print("  [{d}] {s}\n", .{ idx, root });
    }
    try out.print("extra segments -> {s}\n", .{extras_joined});

    try out.flush();
}
