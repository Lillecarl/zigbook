const std = @import("std");

pub fn main() !void {
    const text = "Hello, 世界";

    var view = try std.unicode.Utf8View.init(text);
    var iter = view.iterator();

    var byte_count: usize = 0;
    var codepoint_count: usize = 0;

    while (iter.nextCodepoint()) |codepoint| {
        const len: usize = std.unicode.utf8CodepointSequenceLength(codepoint) catch unreachable;
        const c = iter.bytes[iter.i - len .. iter.i];
        std.debug.print("Code point: U+{X:0>4} ({s})\n", .{ codepoint, c });
        byte_count += c.len;
        codepoint_count += 1;
    }

    std.debug.print("Byte count: {d}, Code point count: {d}\n", .{ text.len, codepoint_count });
}
