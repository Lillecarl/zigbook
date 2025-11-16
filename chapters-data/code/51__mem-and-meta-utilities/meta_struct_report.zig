const std = @import("std");

const Settings = struct {
    render: bool = false,
    retries: u8 = 1,
    mode: []const u8 = "slow",
    log_level: []const u8 = "info",
    extra_paths: []const u8 = "",
};

const Field = std.meta.FieldEnum(Settings);
const whitespace = " \t\r";

const raw_config =
    \\# overrides loaded from a repro case
    \\render = true
    \\retries = 4
    \\mode = fast-render
    \\extra_paths = /srv/www:/srv/cache
;

const ParseError = error{
    UnknownKey,
    BadBool,
    BadInt,
};

fn printValue(out: anytype, value: anytype) !void {
    const T = @TypeOf(value);
    switch (@typeInfo(T)) {
        .pointer => |ptr_info| switch (ptr_info.child) {
            u8 => if (ptr_info.size == .slice or ptr_info.size == .many or ptr_info.size == .c) {
                try out.print("{s}", .{value});
                return;
            },
            else => {},
        },
        else => {},
    }
    try out.print("{any}", .{value});
}

fn parseBool(value: []const u8) ParseError!bool {
    if (std.ascii.eqlIgnoreCase(value, "true") or std.mem.eql(u8, value, "1")) return true;
    if (std.ascii.eqlIgnoreCase(value, "false") or std.mem.eql(u8, value, "0")) return false;
    return error.BadBool;
}

fn applySetting(settings: *Settings, key: []const u8, value: []const u8) ParseError!void {
    const tag = std.meta.stringToEnum(Field, key) orelse return error.UnknownKey;

    switch (tag) {
        .render => settings.render = try parseBool(value),
        .retries => {
            const parsed = std.fmt.parseInt(u16, value, 10) catch return error.BadInt;
            settings.retries = std.math.cast(u8, parsed) orelse return error.BadInt;
        },
        .mode => settings.mode = value,
        .log_level => settings.log_level = value,
        .extra_paths => settings.extra_paths = value,
    }
}

fn emitSchema(out: anytype) !void {
    try out.print("settings schema:\n", .{});
    inline for (std.meta.fields(Settings)) |field| {
        const defaults = Settings{};
        const default_value = @field(defaults, field.name);
        try out.print("  - {s}: {s} (align {d}) default=", .{ field.name, @typeName(field.type), std.meta.alignment(field.type) });
        try printValue(out, default_value);
        try out.print("\n", .{});
    }
}

fn dumpSettings(out: anytype, settings: Settings) !void {
    try out.print("resolved values:\n", .{});
    inline for (std.meta.fields(Settings)) |field| {
        const value = @field(settings, field.name);
        try out.print("  {s} => ", .{field.name});
        try printValue(out, value);
        try out.print("\n", .{});
    }
}

pub fn main() !void {
    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const out = &stdout_writer.interface;

    try emitSchema(out);

    var settings = Settings{};
    var failures: usize = 0;

    var lines = std.mem.tokenizeScalar(u8, raw_config, '\n');
    while (lines.next()) |line| {
        const trimmed = std.mem.trim(u8, line, whitespace);
        if (trimmed.len == 0 or std.mem.startsWith(u8, trimmed, "#")) continue;

        const eql = std.mem.indexOfScalar(u8, trimmed, '=') orelse {
            failures += 1;
            continue;
        };

        const key = std.mem.trim(u8, trimmed[0..eql], whitespace);
        const raw = std.mem.trim(u8, trimmed[eql + 1 ..], whitespace);
        if (key.len == 0) {
            failures += 1;
            continue;
        }

        if (applySetting(&settings, key, raw)) |_| {} else |err| {
            failures += 1;
            try out.print("  warning: {s} -> {any}\n", .{ key, err });
        }
    }

    try dumpSettings(out, settings);
    const tags = std.meta.tags(Field);
    try out.print("field tags visited: {any}\n", .{tags});
    try out.print("parsing failures: {d}\n", .{failures});

    try out.flush();
}
