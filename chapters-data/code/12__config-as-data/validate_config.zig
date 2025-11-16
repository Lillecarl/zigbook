const std = @import("std");

/// Environment mode for the application
/// Determines security requirements and runtime behavior
const Mode = enum { development, staging, production };

/// Main application configuration structure with nested settings
const AppConfig = struct {
    host: []const u8 = "127.0.0.1",
    port: u16 = 8080,
    mode: Mode = .development,
    tls: Tls = .{},
    timeouts: Timeouts = .{},

    /// TLS/SSL configuration for secure connections
    pub const Tls = struct {
        enabled: bool = false,
        cert_path: ?[]const u8 = null,
        key_path: ?[]const u8 = null,
    };

    /// Timeout settings for network operations
    pub const Timeouts = struct {
        connect_ms: u32 = 200,
        read_ms: u32 = 1200,
    };
};

/// Explicit error set for all configuration validation failures
/// Each variant represents a specific invariant violation
const ConfigError = error{
    InvalidPort,
    InsecureProduction,
    MissingTlsMaterial,
    TimeoutOrdering,
};

/// Validates configuration invariants and business rules
/// config: the configuration to validate
/// Returns: ConfigError if any validation rule is violated
fn validate(config: AppConfig) ConfigError!void {
    // Port 0 is reserved and invalid for network binding
    if (config.port == 0) return error.InvalidPort;
    
    // Ports below 1024 require elevated privileges (except standard HTTPS)
    // Reject them to avoid privilege escalation requirements
    if (config.port < 1024 and config.port != 443) return error.InvalidPort;

    // Production environments must enforce TLS to protect data in transit
    if (config.mode == .production and !config.tls.enabled) {
        return error.InsecureProduction;
    }

    // When TLS is enabled, both certificate and private key must be provided
    if (config.tls.enabled) {
        if (config.tls.cert_path == null or config.tls.key_path == null) {
            return error.MissingTlsMaterial;
        }
    }

    // Read timeout must exceed connect timeout to allow data transfer
    // Otherwise connections would time out immediately after establishment
    if (config.timeouts.read_ms < config.timeouts.connect_ms) {
        return error.TimeoutOrdering;
    }
}

/// Reports validation result in human-readable format
/// writer: output destination for the report
/// label: descriptive name for this configuration test case
/// config: the configuration to validate and report on
fn report(writer: anytype, label: []const u8, config: AppConfig) !void {
    try writer.print("{s}: ", .{label});
    
    // Attempt validation and catch any errors
    validate(config) catch |err| {
        // If validation fails, report the error name and return
        return try writer.print("error {s}\n", .{@errorName(err)});
    };
    
    // If validation succeeded, report success
    try writer.print("ok\n", .{});
}

pub fn main() !void {
    // Test case 1: Valid production configuration
    // All security requirements met: TLS enabled with credentials
    const production = AppConfig{
        .host = "example.com",
        .port = 8443,
        .mode = .production,
        .tls = .{
            .enabled = true,
            .cert_path = "certs/app.pem",
            .key_path = "certs/app.key",
        },
        .timeouts = .{
            .connect_ms = 250,
            .read_ms = 1800,
        },
    };

    // Test case 2: Invalid - production mode without TLS
    // Should trigger InsecureProduction error
    const insecure = AppConfig{
        .mode = .production,
        .tls = .{ .enabled = false },
    };

    // Test case 3: Invalid - read timeout less than connect timeout
    // Should trigger TimeoutOrdering error
    const misordered = AppConfig{
        .timeouts = .{
            .connect_ms = 700,
            .read_ms = 500,
        },
    };

    // Test case 4: Invalid - TLS enabled but missing certificate
    // Should trigger MissingTlsMaterial error
    const missing_tls_material = AppConfig{
        .mode = .staging,
        .tls = .{
            .enabled = true,
            .cert_path = null,
            .key_path = "certs/dev.key",
        },
    };

    // Set up buffered stdout writer to reduce syscalls
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    
    // Run validation reports for all test cases
    // Each report will validate the config and print the result
    try report(stdout, "production", production);
    try report(stdout, "insecure", insecure);
    try report(stdout, "misordered", misordered);
    try report(stdout, "missing_tls_material", missing_tls_material);
    
    // Ensure all buffered output is written to stdout
    try stdout.flush();
}
