const std = @import("std");

// Demonstrating library creation
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Create a static library
    const lib = b.addLibrary(.{
        .name = "utils",
        .root_module = b.createModule(.{
            .root_source_file = b.path("utils.zig"),
            .target = target,
            .optimize = optimize,
        }),
        .linkage = .static,
        .version = .{ .major = 1, .minor = 0, .patch = 0 },
    });

    b.installArtifact(lib);

    // Create an executable that links the library
    const exe = b.addExecutable(.{
        .name = "demo",
        .root_module = b.createModule(.{
            .root_source_file = b.path("main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    exe.linkLibrary(lib);
    b.installArtifact(exe);

    const run_step = b.step("run", "Run the demo");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);
}
