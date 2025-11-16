const std = @import("std");

pub fn main() !void {
    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    const m = std.math;
    const latencies = [_]f64{ 0.94, 1.02, 0.87, 1.11, 0.99, 1.05 };

    var sum: f64 = 0;
    var sum_sq: f64 = 0;
    var minimum = latencies[0];
    var maximum = latencies[0];
    for (latencies) |value| {
        sum += value;
        sum_sq += value * value;
        minimum = @min(minimum, value);
        maximum = @max(maximum, value);
    }

    const mean = sum / @as(f64, @floatFromInt(latencies.len));
    const rms = m.sqrt(sum_sq / @as(f64, @floatFromInt(latencies.len)));
    const normalized = m.clamp((mean - 0.8) / 0.6, 0.0, 1.0);

    const turn_degrees: f64 = 72.0;
    const turn_radians = turn_degrees * m.rad_per_deg;
    const right_angle = m.pi / 2.0;
    const approx_right = m.approxEqRel(f64, turn_radians, right_angle, 1e-12);

    const hyp = m.hypot(3.0, 4.0);

    try stdout.print("sample count -> {d}\n", .{latencies.len});
    try stdout.print("min/max -> {d:.2} / {d:.2}\n", .{ minimum, maximum });
    try stdout.print("mean -> {d:.3}\n", .{mean});
    try stdout.print("rms -> {d:.3}\n", .{rms});
    try stdout.print("normalized mean -> {d:.3}\n", .{normalized});
    try stdout.print("72deg in rad -> {d:.6}\n", .{turn_radians});
    try stdout.print("close to right angle? -> {s}\n", .{if (approx_right) "yes" else "no"});
    try stdout.print("hypot(3,4) -> {d:.1}\n", .{hyp});
    try stdout.print("phi constant -> {d:.9}\n", .{m.phi});

    try stdout.flush();
}
