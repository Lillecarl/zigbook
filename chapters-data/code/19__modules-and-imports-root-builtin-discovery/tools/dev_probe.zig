//! Development probe utility for debugging and build information.
//! This module provides diagnostic functions that expose runtime and build-time
//! information, primarily intended for development and debugging purposes.

/// Import the builtin module to access compiler and build information.
const builtin = @import("builtin");

/// Returns a banner string indicating debug instrumentation is active.
/// This function is typically used to signal that diagnostic or debugging
/// features are enabled in the current build.
///
/// Returns: A compile-time known string slice with the instrumentation message.
pub fn banner() []const u8 {
    return "debug-only instrumentation active";
}

/// Returns the Zig compiler version used for the current build.
/// This is useful for logging build information or verifying compatibility
/// across different development environments.
///
/// Returns: A compile-time known string slice containing the Zig version (e.g., "0.11.0").
pub fn buildSession() []const u8 {
    return builtin.zig_version_string;
}
