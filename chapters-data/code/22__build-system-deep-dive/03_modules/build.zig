const std = @import("std");

// Demonstrating module creation and imports
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    
    // Create a reusable module (public)
    const math_mod = b.addModule("math", .{
        .root_source_file = b.path("math.zig"),
        .target = target,
    });
    
    // Create the executable with import of the module
    const exe = b.addExecutable(.{
        .name = "calculator",
        .root_module = b.createModule(.{
            .root_source_file = b.path("main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "math", .module = math_mod },
            },
        }),
    });
    
    b.installArtifact(exe);
    
    const run_step = b.step("run", "Run the calculator");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);
}
