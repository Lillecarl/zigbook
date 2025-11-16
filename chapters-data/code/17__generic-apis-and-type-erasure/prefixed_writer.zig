const std = @import("std");

fn PrefixedWriter(comptime Writer: type) type {
    return struct {
        inner: Writer,
        prefix: []const u8,

        pub fn print(self: *@This(), comptime fmt: []const u8, args: anytype) !void {
            try self.inner.print("[{s}] ", .{self.prefix});
            try self.inner.print(fmt, args);
        }
    };
}

fn withPrefix(writer: anytype, prefix: []const u8) PrefixedWriter(@TypeOf(writer)) {
    return .{
        .inner = writer,
        .prefix = prefix,
    };
}

const ListSink = struct {
    allocator: std.mem.Allocator,
    list: std.ArrayList(u8) = std.ArrayList(u8).empty,

    const Writer = std.io.GenericWriter(*ListSink, std.mem.Allocator.Error, writeFn);

    fn writeFn(self: *ListSink, chunk: []const u8) std.mem.Allocator.Error!usize {
        try self.list.appendSlice(self.allocator, chunk);
        return chunk.len;
    }

    pub fn writer(self: *ListSink) Writer {
        return .{ .context = self };
    }

    pub fn print(self: *ListSink, comptime fmt: []const u8, args: anytype) !void {
        try self.writer().print(fmt, args);
    }

    pub fn deinit(self: *ListSink) void {
        self.list.deinit(self.allocator);
    }
};

pub fn main() !void {
    var stream_storage: [256]u8 = undefined;
    var fixed_stream = std.Io.fixedBufferStream(&stream_storage);
    var pref_stream = withPrefix(fixed_stream.writer(), "stream");
    try pref_stream.print("value = {d}\n", .{42});
    try pref_stream.print("tuple = {any}\n", .{.{ 1, 2, 3 }});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var sink = ListSink{ .allocator = allocator };
    defer sink.deinit();

    var pref_array = withPrefix(sink.writer(), "array");
    try pref_array.print("flags = {any}\n", .{.{ true, false }});
    try pref_array.print("label = {s}\n", .{"generic"});

    std.debug.print("Fixed buffer stream captured:\n{s}", .{fixed_stream.getWritten()});
    std.debug.print("ArrayList writer captured:\n{s}", .{sink.list.items});
}
