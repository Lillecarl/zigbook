
// Import the standard library for build system types and utilities
const std = @import("std");

// Container struct that holds references to project modules
// This allows centralized access to all workspace modules
pub const Modules = struct {
    libA: *std.Build.Module,
    libB: *std.Build.Module,
};

// Creates and configures all project modules with their dependencies
// This function sets up the module dependency graph for the workspace:
// - palette: vendored external dependency
// - libA: internal package with no dependencies
// - libB: internal package that depends on both libA and palette
//
// Parameters:
//   b: Build instance used to create modules
//   target: Compilation target (architecture, OS, ABI)
//   optimize: Optimization mode (Debug, ReleaseSafe, ReleaseFast, ReleaseSmall)
//
// Returns: Modules struct containing references to libA and libB
pub fn addModules(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) Modules {
    // Create module for the vendored palette library
    // Located in vendor directory as an external dependency
    const palette_mod = b.createModule(.{
        .root_source_file = b.path("vendor/palette/palette.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Create module for libA (analytics functionality)
    // This is a standalone library with no external dependencies
    const lib_a = b.addModule("libA", .{
        .root_source_file = b.path("packages/libA/analytics.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Create module for libB (report functionality)
    // Depends on both libA and palette, establishing the dependency chain
    const lib_b = b.addModule("libB", .{
        .root_source_file = b.path("packages/libB/report.zig"),
        .target = target,
        .optimize = optimize,
        // Import declarations allow libB to access libA and palette modules
        .imports = &.{
            .{ .name = "libA", .module = lib_a },
            .{ .name = "palette", .module = palette_mod },
        },
    });

    // Return configured modules for use in build scripts
    return Modules{
        .libA = lib_a,
        .libB = lib_b,
    };
}
