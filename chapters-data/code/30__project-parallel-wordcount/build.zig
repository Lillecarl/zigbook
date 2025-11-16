const std = @import("std");

/// Build script for the parallel wordcount project.
/// Configures and compiles the executable with standard build options.
pub fn build(b: *std.Build) void {
    // Parse target triple from command line (--target flag)
    const target = b.standardTargetOptions(.{});
    
    // Parse optimization level from command line (-Doptimize flag)
    const optimize = b.standardOptimizeOption(.{});

    // Create a module representing our application's entry point.
    // In Zig 0.15.2, modules are explicitly created before being passed to executables.
    const root = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Define the executable artifact, linking it to the root module.
    const exe = b.addExecutable(.{
        .name = "parallel-wc",
        .root_module = root,
    });

    // Register the executable to be installed in zig-out/bin
    b.installArtifact(exe);

    // Create a run command that executes the compiled binary
    const run_cmd = b.addRunArtifact(exe);
    
    // Forward any arguments passed after '--' to the executable
    if (b.args) |args| run_cmd.addArgs(args);

    // Define a 'run' step that users can invoke with 'zig build run'
    const run_step = b.step("run", "Run parallel wordcount");
    run_step.dependOn(&run_cmd.step);
}
