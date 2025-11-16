//! Builds a statistics report using struct literals that forward into the caller's result location.
const std = @import("std");

pub const Report = struct {
    range: struct {
        min: u8,
        max: u8,
    },
    buckets: [4]u32,
};

pub fn buildReport(values: []const u8) Report {
    var histogram = [4]u32{ 0, 0, 0, 0 };

    if (values.len == 0) {
        return .{
            .range = .{ .min = 0, .max = 0 },
            .buckets = histogram,
        };
    }

    var current_min: u8 = std.math.maxInt(u8);
    var current_max: u8 = 0;

    for (values) |value| {
        current_min = @min(current_min, value);
        current_max = @max(current_max, value);
        const bucket_index = value / 64;
        histogram[bucket_index] += 1;
    }

    return .{
        .range = .{ .min = current_min, .max = current_max },
        .buckets = histogram,
    };
}

test "buildReport summarises range and bucket counts" {
    const data = [_]u8{ 3, 19, 64, 129, 200 };
    const report = buildReport(&data);

    try std.testing.expectEqual(@as(u8, 3), report.range.min);
    try std.testing.expectEqual(@as(u8, 200), report.range.max);
    try std.testing.expectEqualSlices(u32, &[_]u32{ 2, 1, 1, 1 }, &report.buckets);
}
