const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const original = "Hello, World!";

    // Encode
    const encoded_len = std.base64.standard.Encoder.calcSize(original.len);
    const encoded = try allocator.alloc(u8, encoded_len);
    defer allocator.free(encoded);
    _ = std.base64.standard.Encoder.encode(encoded, original);

    std.debug.print("Original: {s}\n", .{original});
    std.debug.print("Encoded: {s}\n", .{encoded});

    // Decode
    var decoded_buf: [100]u8 = undefined;
    const decoded_len = try std.base64.standard.Decoder.calcSizeForSlice(encoded);
    try std.base64.standard.Decoder.decode(&decoded_buf, encoded);

    std.debug.print("Decoded: {s}\n", .{decoded_buf[0..decoded_len]});
}
