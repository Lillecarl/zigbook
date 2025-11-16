
// Import the standard library for testing utilities
const std = @import("std");

// Defines the three tonal categories for styled output
pub const Tone = enum { stable, watch, alert };

// Represents a color theme with ANSI escape codes for different tones
// Each tone has a start sequence and there's a shared reset sequence
pub const Theme = struct {
    stable_start: []const u8,
    watch_start: []const u8,
    alert_start: []const u8,
    reset: []const u8,

    // Returns the appropriate ANSI start sequence for the given tone
    pub fn start(self: Theme, tone: Tone) []const u8 {
        return switch (tone) {
            .stable => self.stable_start,
            .watch => self.watch_start,
            .alert => self.alert_start,
        };
    }
};

// Creates a default theme with standard terminal colors:
// stable (green), watch (yellow), alert (red)
pub fn defaultTheme() Theme {
    return Theme{
        .stable_start = "\x1b[32m", // green
        .watch_start = "\x1b[33m",  // yellow
        .alert_start = "\x1b[31m",  // red
        .reset = "\x1b[0m",
    };
}

// Writes styled text to the provided writer by wrapping it with
// ANSI color codes based on the theme and tone
pub fn writeStyled(theme: Theme, tone: Tone, writer: anytype, text: []const u8) !void {
    try writer.print("{s}{s}{s}", .{ theme.start(tone), text, theme.reset });
}

// Verifies that the default theme returns correct ANSI escape codes
test "default theme colors" {
    const theme = defaultTheme();
    try std.testing.expectEqualStrings("\x1b[32m", theme.start(.stable));
    try std.testing.expectEqualStrings("\x1b[0m", theme.reset);
}
