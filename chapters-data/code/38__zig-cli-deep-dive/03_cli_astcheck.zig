//! Utility functions for CLI environment configuration and cross-platform defaults.
//! This module provides helpers for determining cache directories, color support,
//! and default tool configurations based on the target operating system.
const std = @import("std");
const builtin = @import("builtin");

/// Returns the appropriate environment variable key for the cache directory
/// based on the target operating system.
///
/// - Windows uses LOCALAPPDATA for application cache
/// - macOS and iOS use HOME (cache typically goes in ~/Library/Caches)
/// - Unix-like systems prefer XDG_CACHE_HOME for XDG Base Directory compliance
/// - Other systems fall back to HOME directory
pub fn defaultCacheEnvKey() []const u8 {
    return switch (builtin.os.tag) {
        .windows => "LOCALAPPDATA",
        .macos => "HOME",
        .ios => "HOME",
        .linux, .freebsd, .netbsd, .openbsd, .dragonfly, .haiku => "XDG_CACHE_HOME",
        else => "HOME",
    };
}

/// Determines whether ANSI color codes should be used in terminal output
/// based on standard environment variables.
///
/// Follows the informal standard where:
/// - NO_COLOR (any value) disables colors
/// - CLICOLOR_FORCE (any value) forces colors even if not a TTY
/// - Default behavior is to enable colors
///
/// Returns true if ANSI colors should be used, false otherwise.
pub fn preferAnsiColor(env: std.process.EnvMap) bool {
    // Check if colors are explicitly disabled
    if (env.get("NO_COLOR")) |_| return false;
    // Check if colors are explicitly forced
    if (env.get("CLICOLOR_FORCE")) |_| return true;
    // Default to enabling colors
    return true;
}

/// Returns the default command-line arguments for invoking the Zig formatter
/// in check mode (reports formatting issues without modifying files).
pub fn defaultFormatterArgs() []const []const u8 {
    return &.{ "zig", "fmt", "--check" };
}
