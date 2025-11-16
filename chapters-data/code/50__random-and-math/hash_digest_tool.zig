const std = @import("std");

pub fn main() !void {
    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    const input_path = if (args.len > 1) args[1] else "payload.txt";

    var file = try std.fs.cwd().openFile(input_path, .{ .mode = .read_only });
    defer file.close();

    var sha256 = std.crypto.hash.sha2.Sha256.init(.{});
    var buffer: [4096]u8 = undefined;
    while (true) {
        const read = try file.read(&buffer);
        if (read == 0) break;
        sha256.update(buffer[0..read]);
    }

    var digest: [std.crypto.hash.sha2.Sha256.digest_length]u8 = undefined;
    sha256.final(&digest);

    const sample = "payload preview";
    const wyhash = std.hash.Wyhash.hash(0, sample);

    try stdout.print("wyhash(seed=0) {s} -> 0x{x:0>16}\n", .{ sample, wyhash });
    const hex_digest = std.fmt.bytesToHex(digest, .lower);
    try stdout.print("sha256({s}) ->\n  {s}\n", .{ input_path, hex_digest });
    try stdout.print("(remember: sha256 certifies integrity, not authenticity.)\n", .{});

    try stdout.flush();
}
