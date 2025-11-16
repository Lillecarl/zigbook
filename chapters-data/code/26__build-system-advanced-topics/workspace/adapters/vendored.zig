const std = @import("std");
const analytics = @import("analytics");

/// Serializes a metric into a JSON-formatted string representation.
/// 
/// Creates a formatted JSON object containing the metric's name, calculated mean,
/// standard deviation, and performance profile classification. The caller owns
/// the returned memory and must free it when done.
///
/// Returns an allocated string containing the JSON representation, or an error
/// if allocation fails.
pub fn emitJson(metric: analytics.Metric, allocator: std.mem.Allocator) ![]u8 {
    return std.fmt.allocPrint(
        allocator,
        "{{\n  \"name\": \"{s}\",\n  \"mean\": {d:.3},\n  \"deviation\": {d:.3},\n  \"profile\": \"{s}\"\n}}\n",
        .{ metric.name, analytics.mean(metric), analytics.deviation(metric), analytics.highlight(metric) },
    );
}
