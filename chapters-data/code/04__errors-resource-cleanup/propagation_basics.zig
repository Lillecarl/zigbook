const std = @import("std");

// Chapter 4 §1.1 – this sample names an error set and shows how `try` forwards
// failures up to the caller without hiding them along the way.

const ParseError = error{ InvalidDigit, Overflow };

fn decodeDigit(ch: u8) ParseError!u8 {
    return switch (ch) {
        '0'...'9' => @as(u8, ch - '0'),
        else => error.InvalidDigit,
    };
}

fn accumulate(input: []const u8) ParseError!u8 {
    var total: u8 = 0;
    for (input) |ch| {
        // Each digit must parse successfully; `try` re-raises any
        // `ParseError` so the outer function's contract stays accurate.
        const digit = try decodeDigit(ch);
        total = total * 10 + digit;
        if (total > 99) {
            // Propagate a second error variant to demonstrate that callers see
            // a complete vocabulary of what can go wrong.
            return error.Overflow;
        }
    }
    return total;
}

pub fn main() !void {
    const samples = [_][]const u8{ "27", "9x", "120" };

    for (samples) |sample| {
        const value = accumulate(sample) catch |err| {
            // Chapter 4 §1.2 will build on this pattern, but even here we log
            // the error name so failed inputs remain observable.
            std.debug.print("input \"{s}\" failed with {s}\n", .{ sample, @errorName(err) });
            continue;
        };
        std.debug.print("input \"{s}\" -> {}\n", .{ sample, value });
    }
}
