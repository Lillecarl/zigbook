//! Resource-safe error handling patterns with defer and errdefer.

const std = @import("std");

/// Custom error set for data loading operations.
/// Keeping error sets small and explicit helps callers route failures precisely.
pub const LoaderError = error{InvalidNumber};

/// Loads floating-point samples from a UTF-8 text file.
/// Each non-empty line is parsed as an f64.
/// Caller owns the returned slice and must free it with the same allocator.
pub fn loadSamples(dir: std.fs.Dir, allocator: std.mem.Allocator, path: []const u8) ![]f64 {
    // Open the file; propagate any I/O errors to caller
    var file = try dir.openFile(path, .{});
    // Guarantee file handle is released when function exits, regardless of path taken
    defer file.close();

    // Start with an empty list; we'll grow it as we parse lines
    var list = std.ArrayListUnmanaged(f64){};
    // If any error occurs after this point, free the list's backing memory
    errdefer list.deinit(allocator);

    // Read entire file into memory; cap at 64KB for safety
    const contents = try file.readToEndAlloc(allocator, 1 << 16);
    // Free the temporary buffer once we've parsed it
    defer allocator.free(contents);

    // Split contents by newline; iterator yields one line at a time
    var lines = std.mem.splitScalar(u8, contents, '\n');
    while (lines.next()) |line| {
        // Strip leading/trailing whitespace and carriage returns
        const trimmed = std.mem.trim(u8, line, " \t\r");
        // Skip empty lines entirely
        if (trimmed.len == 0) continue;

        // Attempt to parse the line as a float; surface a domain-specific error on failure
        const value = std.fmt.parseFloat(f64, trimmed) catch return LoaderError.InvalidNumber;
        // Append successfully parsed value to the list
        try list.append(allocator, value);
    }

    // Transfer ownership of the backing array to the caller
    return list.toOwnedSlice(allocator);
}

test "loadSamples returns parsed floats" {
    // Create a temporary directory that will be cleaned up automatically
    var tmp_fs = std.testing.tmpDir(.{});
    defer tmp_fs.cleanup();

    // Write sample data to a test file
    const file_path = try tmp_fs.dir.createFile("samples.txt", .{});
    defer file_path.close();
    try file_path.writeAll("1.0\n2.5\n3.75\n");

    // Load and parse the samples; defer ensures cleanup even if assertions fail
    const samples = try loadSamples(tmp_fs.dir, std.testing.allocator, "samples.txt");
    defer std.testing.allocator.free(samples);

    // Verify we parsed exactly three values
    try std.testing.expectEqual(@as(usize, 3), samples.len);
    // Check each value is within acceptable floating-point tolerance
    try std.testing.expectApproxEqAbs(1.0, samples[0], 0.001);
    try std.testing.expectApproxEqAbs(2.5, samples[1], 0.001);
    try std.testing.expectApproxEqAbs(3.75, samples[2], 0.001);
}

test "loadSamples surfaces invalid numbers" {
    // Set up another temporary directory for error-path testing
    var tmp_fs = std.testing.tmpDir(.{});
    defer tmp_fs.cleanup();

    // Write non-numeric content to trigger parsing failure
    const file_path = try tmp_fs.dir.createFile("bad.txt", .{});
    defer file_path.close();
    try file_path.writeAll("not-a-number\n");

    // Confirm that loadSamples returns the expected domain error
    try std.testing.expectError(LoaderError.InvalidNumber, loadSamples(tmp_fs.dir, std.testing.allocator, "bad.txt"));
}
