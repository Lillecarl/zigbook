//! Summarizes struct metadata using @typeInfo and @field.
const std = @import("std");

fn describeStruct(comptime T: type, writer: anytype) !void {
    const info = @typeInfo(T);
    switch (info) {
        .@"struct" => |struct_info| {
            try writer.print("struct {s} has {d} fields", .{ @typeName(T), struct_info.fields.len });
            inline for (struct_info.fields, 0..) |field, index| {
                try writer.print("\n  {d}: {s} : {s}", .{ index, field.name, @typeName(field.type) });
            }
        },
        else => try writer.writeAll("not a struct"),
    }
}

test "describe struct reports field metadata" {
    const Sample = struct {
        id: u32,
        value: ?f64,
    };

    var buffer: [256]u8 = undefined;
    var stream = std.io.fixedBufferStream(&buffer);
    try describeStruct(Sample, stream.writer());
    const summary = stream.getWritten();

    try std.testing.expect(std.mem.containsAtLeast(u8, summary, 1, "id"));
    try std.testing.expect(std.mem.containsAtLeast(u8, summary, 1, "value"));
}

test "describe struct rejects non-struct types" {
    var buffer: [32]u8 = undefined;
    var stream = std.io.fixedBufferStream(&buffer);
    try describeStruct(u8, stream.writer());
    const summary = stream.getWritten();
    try std.testing.expectEqualStrings("not a struct", summary);
}
