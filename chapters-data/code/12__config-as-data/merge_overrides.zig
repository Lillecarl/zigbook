const std = @import("std");

/// Configuration structure for an application with sensible defaults
const AppConfig = struct {
    /// Theme options for the application UI
    pub const Theme = enum { system, light, dark };

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

/// Structure representing optional configuration overrides
/// Each field is optional (nullable) to indicate whether it should override the base config
const Overrides = struct {
    host: ?[]const u8 = null,
    port: ?u16 = null,
    log_level: ?std.log.Level = null,
    instrumentation: ?bool = null,
    theme: ?AppConfig.Theme = null,
    timeouts: ?AppConfig.Timeouts = null,
};

/// Merges a single layer of overrides into a base configuration
/// base: the starting configuration to modify
/// overrides: optional values that should replace corresponding base fields
/// Returns: a new AppConfig with overrides applied
fn merge(base: AppConfig, overrides: Overrides) AppConfig {
    // Start with a copy of the base configuration
    var result = base;
    
    // Iterate over all fields in the Overrides struct at compile time
    inline for (std.meta.fields(Overrides)) |field| {
        // Check if this override field has a non-null value
        if (@field(overrides, field.name)) |value| {
            // If present, replace the corresponding field in result
            @field(result, field.name) = value;
        }
    }
    
    return result;
}

/// Applies a chain of override layers in sequence
/// base: the initial configuration
/// chain: slice of Overrides to apply in order (left to right)
/// Returns: final configuration after all layers are merged
fn apply(base: AppConfig, chain: []const Overrides) AppConfig {
    // Start with the base configuration
    var current = base;
    
    // Apply each override layer in sequence
    // Later layers override earlier ones
    for (chain) |layer| {
        current = merge(current, layer);
    }
    
    return current;
}

/// Helper function to print configuration values in a human-readable format
/// writer: any type implementing write() and print() methods
/// label: descriptive text to identify this configuration dump
/// config: the AppConfig instance to display
fn printSummary(writer: anytype, label: []const u8, config: AppConfig) !void {
    try writer.print("{s}:\n", .{label});
    try writer.print("  host = {s}\n", .{config.host});
    try writer.print("  port = {}\n", .{config.port});
    try writer.print("  log = {s}\n", .{@tagName(config.log_level)});
    try writer.print("  instrumentation = {}\n", .{config.instrumentation});
    try writer.print("  theme = {s}\n", .{@tagName(config.theme)});
    try writer.print("  timeouts = {any}\n", .{config.timeouts});
}

pub fn main() !void {
    // Create base configuration with all default values
    const defaults = AppConfig{};
    
    // Define a profile-level override layer (e.g., development profile)
    // This might come from a profile file or environment-specific settings
    const profile = Overrides{
        .host = "0.0.0.0",
        .port = 9000,
        .log_level = .debug,
        .instrumentation = true,
        .theme = .dark,
        .timeouts = AppConfig.Timeouts{
            .connect_ms = 100,
            .read_ms = 1500,
        },
    };
    
    // Define environment-level overrides (e.g., from environment variables)
    // These override profile settings
    const env = Overrides{
        .host = "config.internal",
        .port = 9443,
        .log_level = .warn,
        .timeouts = AppConfig.Timeouts{
            .connect_ms = 60,
            .read_ms = 1100,
        },
    };
    
    // Define command-line overrides (highest priority)
    // Only overrides specific fields, leaving others unchanged
    const command_line = Overrides{
        .instrumentation = false,
        .theme = .light,
    };

    // Apply all override layers in precedence order:
    // defaults -> profile -> env -> command_line
    // Later layers take precedence over earlier ones
    const final = apply(defaults, &[_]Overrides{ profile, env, command_line });

    // Set up buffered stdout writer to reduce syscalls
    var stdout_buffer: [2048]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    
    // Display progression of configuration through each layer
    try printSummary(stdout, "defaults", defaults);
    try printSummary(stdout, "profile", merge(defaults, profile));
    try printSummary(stdout, "env", merge(defaults, env));
    try printSummary(stdout, "command_line", merge(defaults, command_line));
    
    // Add separator before showing final resolved config
    try stdout.writeByte('\n');
    
    // Display the final merged configuration after all layers applied
    try printSummary(stdout, "resolved", final);
    
    // Ensure all buffered output is written
    try stdout.flush();
}
