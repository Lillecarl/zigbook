
/// Statistical summary of a numerical dataset.
/// Contains computed statistics including central tendency, spread, and sample size.
const std = @import("std");

pub const Stats = struct {
    sample_count: usize,
    min: f64,
    max: f64,
    mean: f64,
    variance: f64,

    /// Calculates the range (difference between maximum and minimum values).
    pub fn range(self: Stats) f64 {
        return self.max - self.min;
    }

    /// Calculates the coefficient of variation (range divided by mean).
    /// Returns 0 if mean is 0 to avoid division by zero.
    pub fn relativeSpread(self: Stats) f64 {
        return if (self.mean == 0) 0 else self.range() / self.mean;
    }
};

/// Computes descriptive statistics for a slice of floating-point values.
/// Uses Welford's online algorithm for numerically stable variance calculation.
/// Panics if the input slice is empty.
pub fn analyze(values: []const f64) Stats {
    std.debug.assert(values.len > 0);

    var min_value: f64 = values[0];
    var max_value: f64 = values[0];
    var mean_value: f64 = 0.0;
    // M2 is the sum of squares of differences from the current mean (Welford's algorithm)
    var m2: f64 = 0.0;
    var index: usize = 0;

    while (index < values.len) : (index += 1) {
        const value = values[index];
        // Track minimum and maximum values
        if (value < min_value) min_value = value;
        if (value > max_value) max_value = value;

        // Welford's online algorithm for mean and variance
        const count = index + 1;
        const delta = value - mean_value;
        mean_value += delta / @as(f64, @floatFromInt(count));
        const delta2 = value - mean_value;
        m2 += delta * delta2;
    }

    // Calculate sample variance using Bessel's correction (n-1)
    const count_f = @as(f64, @floatFromInt(values.len));
    const variance_value = if (values.len > 1)
        m2 / (count_f - 1.0)
    else
        0.0;

    return Stats{
        .sample_count = values.len,
        .min = min_value,
        .max = max_value,
        .mean = mean_value,
        .variance = variance_value,
    };
}

/// Computes the sample standard deviation from precomputed statistics.
/// Standard deviation is the square root of variance.
pub fn sampleStdDev(stats: Stats) f64 {
    return std.math.sqrt(stats.variance);
}

/// Calculates the z-score (standard score) for a given value.
/// Measures how many standard deviations a value is from the mean.
/// Returns 0 if standard deviation is 0 to avoid division by zero.
pub fn zScore(value: f64, stats: Stats) f64 {
    const dev = sampleStdDev(stats);
    if (dev == 0.0) return 0.0;
    return (value - stats.mean) / dev;
}

test "analyze returns correct statistics" {
    const data = [_]f64{ 12.0, 13.5, 11.8, 12.2, 12.0 };
    const stats = analyze(&data);

    try std.testing.expectEqual(@as(usize, data.len), stats.sample_count);
    try std.testing.expectApproxEqRel(12.3, stats.mean, 1e-6);
    try std.testing.expectApproxEqAbs(1.7, stats.range(), 1e-6);
}
