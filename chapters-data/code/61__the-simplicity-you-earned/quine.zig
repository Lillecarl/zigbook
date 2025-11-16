const std = @import("std");

pub fn main() !void {
    const data = "const std = @import(\"std\");\n\npub fn main() !void {{\n    const data = \"{f}\";\n    var buf: [1024]u8 = undefined;\n    var w = std.fs.File.stdout().writer(&buf);\n    try w.interface.print(data, .{{std.zig.fmtString(data)}});\n    try w.interface.flush();\n}}\n";
    var buf: [1024]u8 = undefined;
    var w = std.fs.File.stdout().writer(&buf);
    try w.interface.print(data, .{std.zig.fmtString(data)});
    try w.interface.flush();
}
