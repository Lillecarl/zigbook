const std = @import("std");

// Number of parallel operations per vector
const lanes = 4;
// Vector type that processes 4 f32 values simultaneously using SIMD
const Vec = @Vector(lanes, f32);

/// Loads 4 consecutive f32 values from a slice into a SIMD vector.
/// The caller must ensure that start + 3 is within bounds.
fn loadVec(slice: []const f32, start: usize) Vec {
    return .{
        slice[start + 0],
        slice[start + 1],
        slice[start + 2],
        slice[start + 3],
    };
}

/// Computes the dot product of two f32 slices using scalar operations.
/// This is the baseline implementation that processes one element at a time.
fn dotScalar(values_a: []const f32, values_b: []const f32) f32 {
    std.debug.assert(values_a.len == values_b.len);
    var sum: f32 = 0.0;
    // Multiply corresponding elements and accumulate the sum
    for (values_a, values_b) |a, b| {
        sum += a * b;
    }
    return sum;
}

/// Computes the dot product using SIMD vectorization for improved performance.
/// Processes 4 elements at a time, then reduces the vector accumulator to a scalar.
/// Requires that the input length is a multiple of the lane count (4).
fn dotVectorized(values_a: []const f32, values_b: []const f32) f32 {
    std.debug.assert(values_a.len == values_b.len);
    std.debug.assert(values_a.len % lanes == 0);

    // Initialize accumulator vector with zeros
    var accum: Vec = @splat(0.0);
    var index: usize = 0;
    // Process 4 elements per iteration using SIMD
    while (index < values_a.len) : (index += lanes) {
        const lhs = loadVec(values_a, index);
        const rhs = loadVec(values_b, index);
        // Perform element-wise multiplication and add to accumulator
        accum += lhs * rhs;
    }

    // Sum all lanes of the accumulator vector into a single scalar value
    return @reduce(.Add, accum);
}

// Verifies that the vectorized implementation produces the same result as the scalar version.
test "vectorized dot product matches scalar" {
    const lhs = [_]f32{ 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0 };
    const rhs = [_]f32{ 8.0, 7.0, 6.0, 5.0, 4.0, 3.0, 2.0, 1.0 };
    const scalar = dotScalar(&lhs, &rhs);
    const vector = dotVectorized(&lhs, &rhs);
    // Allow small floating-point error tolerance
    try std.testing.expectApproxEqAbs(scalar, vector, 0.0001);
}
