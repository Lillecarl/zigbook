// Utility to compare two float32 binary dumps.
//
// The files are expected to be raw little-endian 32-bit float arrays. The
// program prints the number of mismatched lanes (based on absolute tolerance)
// and highlights the first few differences for quick diagnostics.

const std = @import("std");

/// Maximum number of mismatched differences to display in diagnostic output
const max_preview = 5;

pub fn main() !void {
    // Initialize allocator with leak detection for development builds
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer switch (gpa.deinit()) {
        .ok => {},
        .leak => std.log.warn("compare_dump leaked memory", .{}),
    };
    const allocator = gpa.allocator();

    // Parse command-line arguments expecting exactly two file paths
    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();
    _ = args.next(); // Skip program name

    const expected_path = args.next() orelse return usageError();
    const actual_path = args.next() orelse return usageError();
    if (args.next()) |_| return usageError(); // Reject extra arguments

    // Load both binary dumps into memory for comparison
    const expected_bytes = try readAll(allocator, expected_path);
    defer allocator.free(expected_bytes);

    const actual_bytes = try readAll(allocator, actual_path);
    defer allocator.free(actual_bytes);

    // Reinterpret raw bytes as f32 slices for element-wise comparison
    const expected = std.mem.bytesAsSlice(f32, expected_bytes);
    const actual = std.mem.bytesAsSlice(f32, actual_bytes);

    // Early exit if array lengths differ
    if (expected.len != actual.len) {
        std.debug.print(
            "length mismatch: expected {d} elements, actual {d} elements\n",
            .{ expected.len, actual.len },
        );
        return;
    }

    // Track total mismatches and collect first few for detailed reporting
    var mismatches: usize = 0;
    var first_few: [max_preview]?Diff = .{null} ** max_preview;

    // Compare each lane using floating-point tolerance to account for minor precision differences
    for (expected, actual, 0..) |lhs, rhs, idx| {
        if (!std.math.approxEqAbs(f32, lhs, rhs, 1e-6)) {
            // Store first N differences for diagnostic display
            if (mismatches < max_preview) {
                first_few[mismatches] = Diff{ .index = idx, .expected = lhs, .actual = rhs };
            }
            mismatches += 1;
        }
    }

    // Print summary of comparison results
    std.debug.print("mismatched lanes: {d}\n", .{mismatches});
    
    // Display detailed information for first few mismatches to aid debugging
    for (first_few) |maybe_diff| {
        if (maybe_diff) |diff| {
            std.debug.print(
                "  lane {d}: expected={d:.6} actual={d:.6}\n",
                .{ diff.index, diff.expected, diff.actual },
            );
        }
    }
}

/// Prints usage information and returns an error when invocation is invalid
fn usageError() !void {
    std.debug.print("usage: compare_dump <expected.bin> <actual.bin>\n", .{});
    return error.InvalidInvocation;
}

/// Reads entire file contents into allocated memory with a 64 MiB size limit
fn readAll(allocator: std.mem.Allocator, path: []const u8) ![]u8 {
    var file = try std.fs.cwd().openFile(path, .{});
    defer file.close();
    return try file.readToEndAlloc(allocator, 1 << 26);
}

/// Captures a single floating-point mismatch with its location and values
const Diff = struct {
    index: usize,
    expected: f32,
    actual: f32,
};
