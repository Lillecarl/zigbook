const std = @import("std");
const testing = std.testing;
const pathutil = @import("path_util.zig").pathutil;

fn ajoin(parts: []const []const u8) ![]u8 {
    return try pathutil.joinAlloc(testing.allocator, parts);
}

test "joinAlloc basic and absolute" {
    const p1 = try ajoin(&.{ "a", "b", "c" });
    defer testing.allocator.free(p1);
    try testing.expectEqualStrings("a" ++ [1]u8{std.fs.path.sep} ++ "b" ++ [1]u8{std.fs.path.sep} ++ "c", p1);

    const p2 = try ajoin(&.{ "/", "usr/", "/bin" });
    defer testing.allocator.free(p2);
    try testing.expectEqualStrings("/usr/bin", p2);

    const p3 = try ajoin(&.{ "", "a", "", "b" });
    defer testing.allocator.free(p3);
    try testing.expectEqualStrings("a" ++ [1]u8{std.fs.path.sep} ++ "b", p3);

    const p4 = try ajoin(&.{ "a/", "/b/" });
    defer testing.allocator.free(p4);
    try testing.expectEqualStrings("a" ++ [1]u8{std.fs.path.sep} ++ "b", p4);
}

test "basename and dirpath edges" {
    try testing.expectEqualStrings("c", pathutil.basename("a/b/c"));
    try testing.expectEqualStrings("b", pathutil.basename("/a/b/"));
    try testing.expectEqualStrings("/", pathutil.basename("////"));
    try testing.expectEqualStrings("", pathutil.basename(""));

    try testing.expectEqualStrings("a/b", pathutil.dirpath("a/b/c"));
    try testing.expectEqualStrings(".", pathutil.dirpath("a"));
    try testing.expectEqualStrings("/", pathutil.dirpath("////"));
}

test "extension and changeExtAlloc" {
    try testing.expectEqualStrings("txt", pathutil.extname("file.txt"));
    try testing.expectEqualStrings("gz", pathutil.extname("a.tar.gz"));
    try testing.expectEqualStrings("", pathutil.extname(".gitignore"));
    try testing.expectEqualStrings("", pathutil.extname("noext"));

    const changed1 = try pathutil.changeExtAlloc(testing.allocator, "a/b/file.txt", "md");
    defer testing.allocator.free(changed1);
    try testing.expectEqualStrings("a/b/file.md", changed1);

    const changed2 = try pathutil.changeExtAlloc(testing.allocator, "a/b/file", "md");
    defer testing.allocator.free(changed2);
    try testing.expectEqualStrings("a/b/file.md", changed2);

    const changed3 = try pathutil.changeExtAlloc(testing.allocator, "a/b/.profile", "txt");
    defer testing.allocator.free(changed3);
    try testing.expectEqualStrings("a/b/.profile.txt", changed3);
}
