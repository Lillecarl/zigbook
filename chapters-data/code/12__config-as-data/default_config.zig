const std = @import("std");

/// Configuration structure for an application with sensible defaults
const AppConfig = struct {
    /// Theme options for the application UI
    pub const Theme = enum { system, light, dark };

    // Default configuration values are specified inline
    host: []const u8 = "127.0.0.1",
    port: u16 = 8080,
    log_level: std.log.Level = .info,
    instrumentation: bool = false,
    theme: Theme = .system,
    timeouts: Timeouts = .{},

    /// Nested configuration for timeout settings
    pub const Timeouts = struct {
        connect_ms: u32 = 200,
        read_ms: u32 = 1200,
    };
};

/// Helper function to print configuration values in a human-readable format
/// writer: any type implementing write() and print() methods
/// label: descriptive text to identify this configuration dump
/// config: the AppConfig instance to display
fn dumpConfig(writer: anytype, label: []const u8, config: AppConfig) !void {
    // Print the label header
    try writer.print("{s}\n", .{label});
    
    // Print each field with proper formatting
    try writer.print("  host = {s}\n", .{config.host});
    try writer.print("  port = {}\n", .{config.port});
    
    // Use @tagName to convert enum values to strings
    try writer.print("  log_level = {s}\n", .{@tagName(config.log_level)});
    try writer.print("  instrumentation = {}\n", .{config.instrumentation});
    try writer.print("  theme = {s}\n", .{@tagName(config.theme)});
    
    // Print nested struct in single line
    try writer.print(
        "  timeouts = .{{ connect_ms = {}, read_ms = {} }}\n",
        .{ config.timeouts.connect_ms, config.timeouts.read_ms },
    );
}

pub fn main() !void {
    // Allocate a fixed buffer for stdout operations
    var stdout_buffer: [2048]u8 = undefined;
    
    // Create a buffered writer for stdout to reduce syscalls
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    // Create a config using all default values (empty initializer)
    const defaults = AppConfig{};
    try dumpConfig(stdout, "defaults ->", defaults);

    // Create a config with several overridden values
    // Fields not specified here retain their defaults from the struct definition
    const tuned = AppConfig{
        .host = "0.0.0.0",        // Bind to all interfaces
        .port = 9090,              // Custom port
        .log_level = .debug,       // More verbose logging
        .instrumentation = true,   // Enable performance monitoring
        .theme = .dark,            // Dark theme instead of system default
        .timeouts = .{             // Override nested timeout values
            .connect_ms = 75,      // Faster connection timeout
            .read_ms = 1500,       // Longer read timeout
        },
    };

    // Add blank line between the two config dumps
    try stdout.writeByte('\n');
    
    // Display the customized configuration
    try dumpConfig(stdout, "overrides ->", tuned);
    
    // Flush the buffer to ensure all output is written to stdout
    try stdout.flush();
}
