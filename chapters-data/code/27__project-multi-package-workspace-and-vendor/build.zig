const std = @import("std");
const deps = @import("deps.zig");

/// Build script for a multi-package workspace demonstrating dependency management.
/// Orchestrates compilation of an executable that depends on local packages (libA, libB)
/// and a vendored dependency (palette), plus provides test and documentation steps.
pub fn build(b: *std.Build) void {
    // Parse target platform and optimization level from command-line options
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Load all workspace modules (libA, libB, palette) via deps.zig
    // This centralizes dependency configuration and makes modules available for import
    const modules = deps.addModules(b, target, optimize);

    // Create the root module for the main executable
    // Explicitly declares dependencies on libA and libB, making them importable
    const root_module = b.createModule(.{
        .root_source_file = b.path("app/main.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            // Map import names to actual modules loaded from deps.zig
            .{ .name = "libA", .module = modules.libA },
            .{ .name = "libB", .module = modules.libB },
        },
    });

    // Define the executable artifact using the configured root module
    const exe = b.addExecutable(.{
        .name = "workspace-dashboard",
        .root_module = root_module,
    });

    // Register the executable for installation into zig-out/bin
    b.installArtifact(exe);

    // Create a command to run the built executable
    const run_cmd = b.addRunArtifact(exe);
    // Forward any extra command-line arguments to the executable
    if (b.args) |args| run_cmd.addArgs(args);

    // Register "zig build run" step to compile and execute the dashboard
    const run_step = b.step("run", "Run the latency dashboard");
    run_step.dependOn(&run_cmd.step);

    // Create test executables for each library module
    // These will run any tests defined in the respective library source files
    const lib_a_tests = b.addTest(.{ .root_module = modules.libA });
    const lib_b_tests = b.addTest(.{ .root_module = modules.libB });

    // Register "zig build test" step to run all library test suites
    const tests_step = b.step("test", "Run library test suites");
    tests_step.dependOn(&b.addRunArtifact(lib_a_tests).step);
    tests_step.dependOn(&b.addRunArtifact(lib_b_tests).step);

    // Generate a text file documenting the workspace module structure
    // This serves as human-readable documentation of the dependency graph
    const mapping = b.addNamedWriteFiles("workspace-artifacts");
    _ = mapping.add("dependency-map.txt",
        \\Modules registered in build.zig:
        \\  libA      -> packages/libA/analytics.zig
        \\  libB      -> packages/libB/report.zig (imports libA, palette)
        \\  palette   -> vendor/palette/palette.zig (anonymous)
        \\  executable -> app/main.zig
    );

    // Install the generated documentation into zig-out/workspace-artifacts
    const install_map = b.addInstallDirectory(.{
        .source_dir = mapping.getDirectory(),
        .install_dir = .prefix,
        .install_subdir = "workspace-artifacts",
    });

    // Register "zig build map" step to generate and install dependency documentation
    const map_step = b.step("map", "Emit dependency map to zig-out");
    map_step.dependOn(&install_map.step);
}
