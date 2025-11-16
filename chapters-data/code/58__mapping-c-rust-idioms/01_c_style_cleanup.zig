//! Reinvents a C-style buffer duplication with Zig's defer-based cleanup.
const std = @import("std");

pub const NormalizeError = error{InvalidCharacter} || std.mem.Allocator.Error;

pub fn duplicateAlphaUpper(allocator: std.mem.Allocator, input: []const u8) NormalizeError![]u8 {
    const buffer = try allocator.alloc(u8, input.len);
    errdefer allocator.free(buffer);

    for (buffer, input) |*dst, src| switch (src) {
        'a'...'z', 'A'...'Z' => dst.* = std.ascii.toUpper(src),
        else => return NormalizeError.InvalidCharacter,
    };

    return buffer;
}

pub fn cStyleDuplicateAlphaUpper(allocator: std.mem.Allocator, input: []const u8) NormalizeError![]u8 {
    const buffer = try allocator.alloc(u8, input.len);
    var ok = false;
    defer if (!ok) allocator.free(buffer);

    for (buffer, input) |*dst, src| switch (src) {
        'a'...'z', 'A'...'Z' => dst.* = std.ascii.toUpper(src),
        else => return NormalizeError.InvalidCharacter,
    };

    ok = true;
    return buffer;
}

test "duplicateAlphaUpper releases buffer on failure" {
    const allocator = std.testing.allocator;
    try std.testing.expectError(NormalizeError.InvalidCharacter, duplicateAlphaUpper(allocator, "zig-0"));
}

test "c style duplicate succeeds with valid input" {
    const allocator = std.testing.allocator;
    const dup = try cStyleDuplicateAlphaUpper(allocator, "zig");
    defer allocator.free(dup);
    try std.testing.expectEqualStrings("ZIG", dup);
}
