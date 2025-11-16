
// This module demonstrates how Zig's module system distinguishes between different roles:
// programs (with main), libraries (exposing public APIs), and hybrid modules.
// It showcases introspection of module characteristics and role-based decision making.

const std = @import("std");
const roles = @import("role_checks.zig");
const manifest_pkg = @import("pkg/manifest.zig");

/// List of public declarations intentionally exported by the root module.
/// This array defines the public API surface that other modules can rely on.
/// It serves as documentation and can be used for validation or tooling.
pub const PublicSurface = [_][]const u8{
    "main",
    "libraryManifest",
    "PublicSurface",
};

/// Provide a canonical manifest describing the library surface that this module exposes.
/// Other modules import this helper to reason about the package-level API.
/// Returns a Manifest struct containing metadata about the library's public interface.
pub fn libraryManifest() manifest_pkg.Manifest {
    // Delegate to the manifest package to construct a sample library descriptor
    return manifest_pkg.sampleLibrary();
}

/// Entry point demonstrating module role classification and vocabulary.
/// Analyzes both the root module and a library module, printing their characteristics:
/// - Whether they export a main function (indicating program vs library intent)
/// - Public symbol counts (API surface area)
/// - Role recommendations based on module structure
pub fn main() !void {
    // Use a fixed-size stack buffer for stdout to avoid heap allocation
    var stdout_buffer: [768]u8 = undefined;
    var file_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &file_writer.interface;

    // Capture snapshots of module characteristics for analysis
    const root_snapshot = roles.rootSnapshot();
    const library_snapshot = roles.librarySnapshot();
    // Retrieve role-based decision guidance
    const decisions = roles.decisions();

    try stdout.print("== Module vocabulary demo ==\n", .{});
    
    // Display root module role determination based on main export
    try stdout.print(
        "root exports main? {s} → treat as {s}\n",
        .{
            if (root_snapshot.exports_main) "yes" else "no",
            root_snapshot.role,
        },
    );
    
    // Show the number of public declarations in the root module
    try stdout.print(
        "root public surface: {d} declarations\n",
        .{root_snapshot.public_symbol_count},
    );
    
    // Display library module metadata: name, version, and main export status
    try stdout.print(
        "library '{s}' v{s} exports main? {s}\n",
        .{
            library_snapshot.name,
            library_snapshot.version,
            if (library_snapshot.exports_main) "yes" else "no",
        },
    );
    
    // Show the count of public modules or symbols in the library
    try stdout.print(
        "library modules listed: {d}\n",
        .{library_snapshot.public_symbol_count},
    );
    
    // Print architectural guidance for different module design goals
    try stdout.print("intent cheat sheet:\n", .{});
    for (decisions) |entry| {
        try stdout.print("  - {s} → {s}\n", .{ entry.goal, entry.recommendation });
    }

    // Flush buffered output to ensure all content is written
    try stdout.flush();
}
