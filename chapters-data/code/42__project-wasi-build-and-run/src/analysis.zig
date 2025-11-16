
// This module provides log analysis functionality for counting severity levels in log files.
// It demonstrates basic string parsing and struct usage in Zig.
const std = @import("std");

// LogStats holds the count of each log severity level found during analysis.
// All fields are initialized to zero by default, representing no logs counted yet.
pub const LogStats = struct {
    info_count: u32 = 0,
    warn_count: u32 = 0,
    error_count: u32 = 0,
};

/// Analyze log content, counting severity keywords.
/// Returns statistics in a LogStats struct.
pub fn analyzeLog(content: []const u8) LogStats {
    // Initialize stats with all counts at zero
    var stats = LogStats{};
    
    // Create an iterator that splits the content by newline characters
    // This allows us to process the log line by line
    var it = std.mem.splitScalar(u8, content, '\n');

    // Process each line in the log content
    while (it.next()) |line| {
        // Count occurrences of severity keywords
        // indexOf returns an optional - if found, we increment the corresponding counter
        if (std.mem.indexOf(u8, line, "INFO")) |_| {
            stats.info_count += 1;
        }
        if (std.mem.indexOf(u8, line, "WARN")) |_| {
            stats.warn_count += 1;
        }
        if (std.mem.indexOf(u8, line, "ERROR")) |_| {
            stats.error_count += 1;
        }
    }

    return stats;
}

// Test basic log analysis with multiple severity levels
test "analyzeLog basic counting" {
    const input = "INFO startup\nERROR failed\nWARN retry\nINFO success\n";

    const stats = analyzeLog(input);
    
    // Verify each severity level was counted correctly
    try std.testing.expectEqual(@as(u32, 2), stats.info_count);
    try std.testing.expectEqual(@as(u32, 1), stats.warn_count);
    try std.testing.expectEqual(@as(u32, 1), stats.error_count);
}

// Test that empty input produces zero counts for all severity levels
test "analyzeLog empty input" {
    const input = "";

    const stats = analyzeLog(input);
    
    // All counts should remain at their default zero value
    try std.testing.expectEqual(@as(u32, 0), stats.info_count);
    try std.testing.expectEqual(@as(u32, 0), stats.warn_count);
    try std.testing.expectEqual(@as(u32, 0), stats.error_count);
}
