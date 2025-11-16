const std = @import("std");

pub fn main() !void {
    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    const seed: u64 = 0x0006_7B20; // 424,224 in decimal
    var prng = std.Random.DefaultPrng.init(seed);
    var rand = prng.random();

    const dice_roll = rand.intRangeAtMost(u8, 1, 6);
    const coin = if (rand.boolean()) "heads" else "tails";
    var ladder = [_]u8{ 0, 1, 2, 3, 4, 5 };
    rand.shuffle(u8, ladder[0..]);

    const unit_float = rand.float(f64);

    var reproducible = [_]u32{ undefined, undefined, undefined };
    var check_prng = std.Random.DefaultPrng.init(seed);
    var check_rand = check_prng.random();
    for (&reproducible) |*slot| {
        slot.* = check_rand.int(u32);
    }

    try stdout.print("seed=0x{X:0>8}\n", .{seed});
    try stdout.print("d6 roll -> {d}\n", .{dice_roll});
    try stdout.print("coin flip -> {s}\n", .{coin});
    try stdout.print("shuffled ladder -> {any}\n", .{ladder});
    try stdout.print("unit float -> {d:.6}\n", .{unit_float});
    try stdout.print("first three u32 -> {any}\n", .{reproducible});

    try stdout.flush();
}
