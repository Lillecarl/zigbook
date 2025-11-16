
// Import standard library for core functionality
const std = @import("std");
// Import analytics module for metric data structures
const analytics = @import("analytics");
// Import reporting module for metric rendering
const reporting = @import("reporting");
// Import adapters module for data format conversion
const adapters = @import("adapters");

/// Application entry point demonstrating workspace dependency usage
/// Shows how to use multiple workspace modules together for metric processing
pub fn main() !void {
    // Create a fixed-size buffer for stdout operations to avoid dynamic allocation
    var stdout_buffer: [512]u8 = undefined;
    // Initialize a buffered writer for stdout to improve I/O performance
    var writer_state = std.fs.File.stdout().writer(&stdout_buffer);
    const out = &writer_state.interface;

    // Create a sample metric with response time measurements in milliseconds
    const metric = analytics.Metric{
        .name = "response_ms",
        .values = &.{ 12.0, 12.4, 11.9, 12.1, 17.0, 12.3 },
    };

    // Render the metric using the reporting module's formatting
    try reporting.render(metric, out);

    // Initialize general purpose allocator for JSON serialization
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // Ensure allocator cleanup on function exit
    defer _ = gpa.deinit();

    // Convert metric to JSON format using the adapters module
    const json = try adapters.emitJson(metric, gpa.allocator());
    // Free allocated JSON string when done
    defer gpa.allocator().free(json);

    // Output the JSON representation of the metric
    try out.print("json export: {s}\n", .{json});
    // Flush buffered output to ensure all data is written
    try out.flush();
}
