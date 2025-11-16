//! Style baseline example demonstrating naming, documentation, and tests.

const std = @import("std");

/// Error set for statistical computation failures.
/// Intentionally narrow to allow precise error handling by callers.
pub const StatsError = error{EmptyInput};

/// Combined error set for logging operations.
/// Merges statistical errors with output formatting failures.
pub const LogError = StatsError || error{OutputTooSmall};

/// Calculates the arithmetic mean of the provided samples.
///
/// Parameters:
///  - `samples`: slice of `f64` values collected from a measurement series.
///
/// Returns the mean as `f64` or `StatsError.EmptyInput` when `samples` is empty.
pub fn mean(samples: []const f64) StatsError!f64 {
    // Guard against division by zero; return domain-specific error for empty input
    if (samples.len == 0) return StatsError.EmptyInput;

    // Accumulate the sum of all sample values
    var total: f64 = 0.0;
    for (samples) |value| {
        total += value;
    }
    
    // Convert sample count to floating-point for precise division
    const count = @as(f64, @floatFromInt(samples.len));
    return total / count;
}

/// Computes the mean and prints the result using the supplied writer.
/// 
/// Accepts any writer type that conforms to the standard writer interface,
/// enabling flexible output destinations (files, buffers, sockets).
pub fn logMean(writer: anytype, samples: []const f64) LogError!void {
    // Delegate computation to mean(); propagate any statistical errors
    const value = try mean(samples);
    
    // Attempt to format and write result; catch writer-specific failures
    writer.print("mean = {d:.3}\n", .{value}) catch {
        // Translate opaque writer errors into our domain-specific error set
        return error.OutputTooSmall;
    };
}

/// Helper for comparing floating-point values with tolerance.
/// Wraps std.math.approxEqAbs to work seamlessly with test error handling.
fn assertApproxEqual(expected: f64, actual: f64, tolerance: f64) !void {
    try std.testing.expect(std.math.approxEqAbs(f64, expected, actual, tolerance));
}

test "mean handles positive numbers" {
    // Verify mean of [2.0, 3.0, 4.0] equals 3.0 within floating-point tolerance
    try assertApproxEqual(3.0, try mean(&[_]f64{ 2.0, 3.0, 4.0 }), 0.001);
}

test "mean returns error on empty input" {
    // Confirm that an empty slice triggers the expected domain error
    try std.testing.expectError(StatsError.EmptyInput, mean(&[_]f64{}));
}

test "logMean forwards formatted output" {
    // Allocate a fixed buffer to capture written output
    var storage: [128]u8 = undefined;
    var stream = std.io.fixedBufferStream(&storage);

    // Write mean result to the in-memory buffer
    try logMean(stream.writer(), &[_]f64{ 1.0, 2.0, 3.0 });
    
    // Retrieve what was written and verify it contains the expected label
    const rendered = stream.getWritten();
    try std.testing.expect(std.mem.containsAtLeast(u8, rendered, 1, "mean"));
}
