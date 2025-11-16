//! Shows how errdefer keeps allocations balanced when joining user snippets.
const std = @import("std");

pub const SnippetError = error{EmptyInput} || std.mem.Allocator.Error;

pub fn joinUpperSnippets(allocator: std.mem.Allocator, parts: []const []const u8) SnippetError![]u8 {
    if (parts.len == 0) return SnippetError.EmptyInput;

    var list = std.ArrayListUnmanaged(u8){};
    errdefer list.deinit(allocator);

    for (parts, 0..) |part, index| {
        if (index != 0) try list.append(allocator, ' ');
        for (part) |ch| try list.append(allocator, std.ascii.toUpper(ch));
    }

    return list.toOwnedSlice(allocator);
}

test "joinUpperSnippets capitalizes and joins input" {
    const allocator = std.testing.allocator;
    const result = try joinUpperSnippets(allocator, &[_][]const u8{ "zig", "cookbook" });
    defer allocator.free(result);

    try std.testing.expectEqualStrings("ZIG COOKBOOK", result);
}

test "joinUpperSnippets surfaces empty-input error" {
    const allocator = std.testing.allocator;
    try std.testing.expectError(SnippetError.EmptyInput, joinUpperSnippets(allocator, &[_][]const u8{}));
}
