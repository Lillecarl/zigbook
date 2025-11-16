//! Demonstrates layering domain-specific error sets when loading configuration.
const std = @import("std");

pub const ParseError = error{
    MissingField,
    InvalidPort,
};

pub const SourceError = error{
    NotFound,
    PermissionDenied,
};

pub const LoadError = SourceError || ParseError;

const SimulatedSource = struct {
    payload: ?[]const u8 = null,
    failure: ?SourceError = null,

    fn fetch(self: SimulatedSource) SourceError![]const u8 {
        if (self.failure) |err| return err;
        return self.payload orelse SourceError.NotFound;
    }
};

fn parsePort(text: []const u8) ParseError!u16 {
    var iter = std.mem.splitScalar(u8, text, '=');
    const key = iter.next() orelse return ParseError.MissingField;
    const value = iter.next() orelse return ParseError.MissingField;
    if (!std.mem.eql(u8, key, "PORT")) return ParseError.MissingField;
    return std.fmt.parseInt(u16, value, 10) catch ParseError.InvalidPort;
}

pub fn loadPort(source: SimulatedSource) LoadError!u16 {
    const line = source.fetch() catch |err| switch (err) {
        SourceError.NotFound => return LoadError.NotFound,
        SourceError.PermissionDenied => return LoadError.PermissionDenied,
    };

    return parsePort(line) catch |err| switch (err) {
        ParseError.MissingField => return LoadError.MissingField,
        ParseError.InvalidPort => return LoadError.InvalidPort,
    };
}

test "successful load yields parsed port" {
    const source = SimulatedSource{ .payload = "PORT=8080" };
    try std.testing.expectEqual(@as(u16, 8080), try loadPort(source));
}

test "parse errors bubble through composed union" {
    const source = SimulatedSource{ .payload = "HOST=example" };
    try std.testing.expectError(LoadError.MissingField, loadPort(source));
}

test "source failures remain precise" {
    const source = SimulatedSource{ .failure = SourceError.PermissionDenied };
    try std.testing.expectError(LoadError.PermissionDenied, loadPort(source));
}
