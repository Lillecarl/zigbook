
// Analytics library for statistical calculations on metrics
const std = @import("std");

// Represents a named metric with associated numerical values
pub const Metric = struct {
    name: []const u8,
    values: []const f64,
};

// Calculates the arithmetic mean (average) of all values in a metric
// Returns the sum of all values divided by the count
pub fn mean(metric: Metric) f64 {
    var total: f64 = 0;
    for (metric.values) |value| {
        total += value;
    }
    return total / @as(f64, @floatFromInt(metric.values.len));
}

// Calculates the standard deviation of values in a metric
// Uses the population standard deviation formula: sqrt(sum((x - mean)^2) / n)
pub fn deviation(metric: Metric) f64 {
    const avg = mean(metric);
    var accum: f64 = 0;
    // Sum the squared differences from the mean
    for (metric.values) |value| {
        const delta = value - avg;
        accum += delta * delta;
    }
    // Return the square root of the variance
    return std.math.sqrt(accum / @as(f64, @floatFromInt(metric.values.len)));
}

// Classifies a metric as "variable" or "stable" based on its standard deviation
// Metrics with deviation > 3.0 are considered variable, otherwise stable
pub fn highlight(metric: Metric) []const u8 {
    return if (deviation(metric) > 3.0)
        "variable"
    else
        "stable";
}
