
// Import standard library for testing utilities
const std = @import("std");
// Import analytics package (libA) for statistical analysis
const analytics = @import("libA");
// Import palette package for theming and styled output
const palette = @import("palette");

/// Represents a named collection of numerical data points for analysis
pub const Dataset = struct {
    name: []const u8,
    values: []const f64,
};

/// Re-export Theme from palette package for consistent theming across reports
pub const Theme = palette.Theme;

/// Defines threshold values that determine status classification
/// based on statistical spread of data
pub const Thresholds = struct {
    watch: f64,  // Threshold for watch status (lower severity)
    alert: f64,  // Threshold for alert status (higher severity)
};

/// Represents the health status of a dataset based on its statistical spread
pub const Status = enum { stable, watch, alert };

/// Determines the status of a dataset by comparing its relative spread
/// against defined thresholds
pub fn status(stats: analytics.Stats, thresholds: Thresholds) Status {
    const spread = stats.relativeSpread();
    // Check against alert threshold first (highest severity)
    if (spread >= thresholds.alert) return .alert;
    // Then check watch threshold (medium severity)
    if (spread >= thresholds.watch) return .watch;
    // Default to stable if below all thresholds
    return .stable;
}

/// Returns the default theme from the palette package
pub fn defaultTheme() Theme {
    return palette.defaultTheme();
}

/// Maps a Status value to its corresponding palette Tone for styling
pub fn tone(status_value: Status) palette.Tone {
    return switch (status_value) {
        .stable => .stable,
        .watch => .watch,
        .alert => .alert,
    };
}

/// Converts a Status value to its string representation
pub fn label(status_value: Status) []const u8 {
    return switch (status_value) {
        .stable => "stable",
        .watch => "watch",
        .alert => "alert",
    };
}

/// Renders a formatted table displaying statistical analysis of multiple datasets
/// with color-coded status indicators based on thresholds
pub fn renderTable(
    writer: anytype,
    data_sets: []const Dataset,
    thresholds: Thresholds,
    theme: Theme,
) !void {
    // Print table header with column names
    try writer.print("{s: <12} {s: <10} {s: <10} {s: <10} {s}\n", .{
        "dataset", "status", "mean", "range", "samples",
    });
    // Print separator line
    try writer.print("{s}\n", .{"-----------------------------------------------"});

    // Process and display each dataset
    for (data_sets) |data| {
        // Compute statistics for current dataset
        const stats = analytics.analyze(data.values);
        const status_value = status(stats, thresholds);

        // Print dataset name
        try writer.print("{s: <12} ", .{data.name});
        // Print styled status label with theme-appropriate color
        try palette.writeStyled(theme, tone(status_value), writer, label(status_value));
        // Print statistical values: mean, range, and sample count
        try writer.print(
            " {d: <10.2} {d: <10.2} {d: <10}\n",
            .{ stats.mean, stats.range(), stats.sample_count },
        );
    }
}

// Verifies that status classification correctly responds to different
// levels of data spread relative to defined thresholds
test "status thresholds" {
    const thresholds = Thresholds{ .watch = 0.05, .alert = 0.12 };

    // Test with tightly clustered values (low spread) - should be stable
    const tight = analytics.analyze(&.{ 99.8, 100.1, 100.0 });
    try std.testing.expectEqual(Status.stable, status(tight, thresholds));

    // Test with widely spread values (high spread) - should trigger alert
    const drift = analytics.analyze(&.{ 100.0, 112.0, 96.0 });
    try std.testing.expectEqual(Status.alert, status(drift, thresholds));
}
