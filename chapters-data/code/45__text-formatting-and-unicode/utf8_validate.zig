const std = @import("std");

pub fn main() void {
    const valid = "Hello, 世界";
    const invalid = "\xff\xfe";

    if (std.unicode.utf8ValidateSlice(valid)) {
        std.debug.print("Valid UTF-8: {s}\n", .{valid});
    }

    if (!std.unicode.utf8ValidateSlice(invalid)) {
        std.debug.print("Invalid UTF-8 detected\n", .{});
    }
}
