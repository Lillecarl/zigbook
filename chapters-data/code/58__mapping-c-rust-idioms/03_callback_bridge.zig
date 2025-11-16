//! Converts a C function-pointer callback pattern into type-safe Zig shims.
const std = @import("std");

pub const LegacyCallback = *const fn (ctx: *anyopaque) void;

fn callLegacy(callback: LegacyCallback, ctx: *anyopaque) void {
    callback(ctx);
}

const Counter = struct {
    value: u32,
};

fn incrementShim(ctx: *anyopaque) void {
    const counter: *Counter = @ptrCast(@alignCast(ctx));
    counter.value += 1;
}

pub fn incrementViaLegacy(counter: *Counter) void {
    callLegacy(incrementShim, counter);
}

pub fn dispatchWithContext(comptime Handler: type, ctx: *Handler) void {
    const shim = struct {
        fn invoke(raw: *anyopaque) void {
            const typed: *Handler = @ptrCast(@alignCast(raw));
            Handler.handle(typed);
        }
    };

    callLegacy(shim.invoke, ctx);
}

const Stats = struct {
    total: u32 = 0,

    fn handle(self: *Stats) void {
        self.total += 2;
    }
};

test "incrementViaLegacy integrates with C-style callback" {
    var counter = Counter{ .value = 0 };
    incrementViaLegacy(&counter);
    try std.testing.expectEqual(@as(u32, 1), counter.value);
}

test "dispatchWithContext adapts trait-like handle method" {
    var stats = Stats{};
    dispatchWithContext(Stats, &stats);
    try std.testing.expectEqual(@as(u32, 2), stats.total);
}
