const std = @import("std");

pub fn greet() []const u8 {
    std.debug.assert(true);
    return "extras namespace discovered via file path";
}
