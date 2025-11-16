const std = @import("std");

// Demonstrating test integration
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    
    const lib_mod = b.addModule("mylib", .{
        .root_source_file = b.path("lib.zig"),
        .target = target,
    });
    
    // Create tests for the library module
    const lib_tests = b.addTest(.{
        .root_module = lib_mod,
    });
    
    const run_lib_tests = b.addRunArtifact(lib_tests);
    
    // Create a test step
    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&run_lib_tests.step);
    
    // Also create an executable that uses the library
    const exe = b.addExecutable(.{
        .name = "app",
        .root_module = b.createModule(.{
            .root_source_file = b.path("main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "mylib", .module = lib_mod },
            },
        }),
    });
    
    b.installArtifact(exe);
}
