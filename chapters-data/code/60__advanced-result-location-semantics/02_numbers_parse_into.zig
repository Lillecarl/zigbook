//! Demonstrates manual result locations by filling a struct through a pointer parameter.
const std = @import("std");

pub const ParseError = error{
    TooManyValues,
    InvalidNumber,
};

pub const Numbers = struct {
    len: usize = 0,
    data: [16]u32 = undefined,

    pub fn slice(self: *const Numbers) []const u32 {
        return self.data[0..self.len];
    }
};

pub fn parseInto(result: *Numbers, text: []const u8) ParseError!void {
    result.* = Numbers{};
    result.data = std.mem.zeroes([16]u32);

    var tokenizer = std.mem.tokenizeAny(u8, text, ", ");
    while (tokenizer.next()) |word| {
        if (result.len == result.data.len) return ParseError.TooManyValues;
        const value = std.fmt.parseInt(u32, word, 10) catch return ParseError.InvalidNumber;
        result.data[result.len] = value;
        result.len += 1;
    }
}

pub fn parseNumbers(text: []const u8) ParseError!Numbers {
    var scratch: Numbers = undefined;
    try parseInto(&scratch, text);
    return scratch;
}

test "parseInto fills caller-provided storage" {
    var numbers: Numbers = .{};
    try parseInto(&numbers, "7,11,42");
    try std.testing.expectEqualSlices(u32, &[_]u32{ 7, 11, 42 }, numbers.slice());
}

test "parseNumbers returns the same shape without extra copies" {
    const owned = try parseNumbers("1 2 3");
    try std.testing.expectEqual(@as(usize, 3), owned.len);
    try std.testing.expectEqualSlices(u32, &[_]u32{ 1, 2, 3 }, owned.data[0..owned.len]);
}
