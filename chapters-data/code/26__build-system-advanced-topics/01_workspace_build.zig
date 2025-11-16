const std = @import("std");

pub fn build(b: *std.Build) void {
    // Standard target and optimization options allow the build to be configured
    // for different architectures and optimization levels via CLI flags
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Create the analytics module - the foundational module that provides
    // core metric calculation and analysis capabilities
    const analytics_mod = b.addModule("analytics", .{
        .root_source_file = b.path("workspace/analytics/lib.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Create the reporting module - depends on analytics to format and display metrics
    // Uses addModule() which both creates and registers the module in one step
    const reporting_mod = b.addModule("reporting", .{
        .root_source_file = b.path("workspace/reporting/lib.zig"),
        .target = target,
        .optimize = optimize,
        // Import analytics module to access metric types and computation functions
        .imports = &.{.{ .name = "analytics", .module = analytics_mod }},
    });

    // Create the adapters module using createModule() - creates but does not register
    // This demonstrates an anonymous module that other code can import but won't
    // appear in the global module namespace
    const adapters_mod = b.createModule(.{
        .root_source_file = b.path("workspace/adapters/vendored.zig"),
        .target = target,
        .optimize = optimize,
        // Adapters need analytics to serialize metric data
        .imports = &.{.{ .name = "analytics", .module = analytics_mod }},
    });

    // Create the main application module that orchestrates all dependencies
    // This demonstrates how a root module can compose multiple imported modules
    const app_module = b.createModule(.{
        .root_source_file = b.path("workspace/app/main.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            // Import all three workspace modules to access their functionality
            .{ .name = "analytics", .module = analytics_mod },
            .{ .name = "reporting", .module = reporting_mod },
            .{ .name = "adapters", .module = adapters_mod },
        },
    });

    // Create the executable artifact using the composed app module as its root
    // The root_module field replaces the legacy root_source_file approach
    const exe = b.addExecutable(.{
        .name = "workspace-app",
        .root_module = app_module,
    });

    // Install the executable to zig-out/bin so it can be run after building
    b.installArtifact(exe);

    // Set up a run command that executes the built executable
    const run_cmd = b.addRunArtifact(exe);
    // Forward any command-line arguments passed to the build system to the executable
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // Create a custom build step "run" that users can invoke with `zig build run`
    const run_step = b.step("run", "Run workspace app with registered modules");
    run_step.dependOn(&run_cmd.step);

    // Create a named write files step to document the module dependency graph
    // This is useful for understanding the workspace structure without reading code
    const graph_files = b.addNamedWriteFiles("graph");
    // Generate a text file documenting the module registration hierarchy
    _ = graph_files.add("module-graph.txt",
        \\workspace module registration map:
        \\  analytics  -> workspace/analytics/lib.zig
        \\  reporting  -> workspace/reporting/lib.zig (imports analytics)
        \\  adapters   -> (anonymous) workspace/adapters/vendored.zig
        \\  exe root   -> workspace/app/main.zig
    );

    // Create a custom build step "graph" that generates module documentation
    // Users can invoke this with `zig build graph` to output the dependency map
    const graph_step = b.step("graph", "Emit module graph summary to zig-out");
    graph_step.dependOn(&graph_files.step);
}
