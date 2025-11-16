// Main application entry point that demonstrates multi-package workspace usage
// by generating a performance report table with multiple datasets.

// Import the standard library for I/O operations
const std = @import("std");
// Import the reporting library (libB) from the workspace
const report = @import("libB");

/// Application entry point that creates and renders a performance monitoring report.
/// Demonstrates integration with the libB package for generating formatted tables
/// with threshold-based highlighting.
pub fn main() !void {
    // Allocate a fixed buffer for stdout to avoid dynamic allocation
    var stdout_buffer: [1024]u8 = undefined;
    // Create a buffered writer for efficient stdout operations
    var writer_state = std.fs.File.stdout().writer(&stdout_buffer);
    // Get the generic writer interface for use with the report library
    const out = &writer_state.interface;

    // Define sample performance datasets for different system components
    // Each dataset contains a component name and an array of performance values
    const datasets = [_]report.Dataset{
        .{ .name = "frontend", .values = &.{ 112.0, 109.5, 113.4, 112.2, 111.9 } },
        .{ .name = "checkout", .values = &.{ 98.0, 101.0, 104.4, 99.1, 100.5 } },
        .{ .name = "analytics", .values = &.{ 67.0, 89.4, 70.2, 91.0, 69.5 } },
    };

    // Configure monitoring thresholds: 8% variance triggers watch, 20% triggers alert
    const thresholds = report.Thresholds{ .watch = 0.08, .alert = 0.2 };
    // Use the default color theme provided by the report library
    const theme = report.defaultTheme();

    // Render the formatted report table to the buffered writer
    try report.renderTable(out, &datasets, thresholds, theme);
    // Flush the buffer to ensure all output is written to stdout
    try out.flush();
}
