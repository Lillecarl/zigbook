//! Reporting module for displaying analytics metrics in various formats.
//! This module provides utilities to render metrics as human-readable text
//! or export them in CSV format for further analysis.

const std = @import("std");
const analytics = @import("analytics");

/// Renders a metric's statistics to a writer in a human-readable format.
/// Outputs the metric name, number of data points, mean, standard deviation,
/// and performance profile label.
///
/// Parameters:
///   - metric: The analytics metric to render
///   - writer: Any writer interface that supports the print() method
///
/// Returns an error if writing to the output fails.
pub fn render(metric: analytics.Metric, writer: anytype) !void {
    try writer.print("metric: {s}\n", .{metric.name});
    try writer.print("count: {}\n", .{metric.values.len});
    try writer.print("mean: {d:.2}\n", .{analytics.mean(metric)});
    try writer.print("deviation: {d:.2}\n", .{analytics.deviation(metric)});
    try writer.print("profile: {s}\n", .{analytics.highlight(metric)});
}

/// Exports a metric's statistics as a CSV-formatted string.
/// Creates a two-row CSV with headers and a single data row containing
/// the metric's name, mean, deviation, and highlight label.
///
/// Parameters:
///   - metric: The analytics metric to export
///   - allocator: Memory allocator for the resulting string
///
/// Returns a heap-allocated CSV string, or an error if allocation or formatting fails.
/// Caller is responsible for freeing the returned memory.
pub fn csv(metric: analytics.Metric, allocator: std.mem.Allocator) ![]u8 {
    return std.fmt.allocPrint(
        allocator,
        "name,mean,deviation,label\n{s},{d:.3},{d:.3},{s}\n",
        .{ metric.name, analytics.mean(metric), analytics.deviation(metric), analytics.highlight(metric) },
    );
}
