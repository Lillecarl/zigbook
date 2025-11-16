const std = @import("std");

// Minimal build.zig: single executable, no options
// Demonstrates the simplest possible build script for the Zig build system.
pub fn build(b: *std.Build) void {
    // Create an executable compilation step with minimal configuration.
    // This represents the fundamental pattern for producing a binary artifact.
    const exe = b.addExecutable(.{
        // The output binary name (becomes "hello" or "hello.exe")
        .name = "hello",
        // Configure the root module with source file and compilation settings
        .root_module = b.createModule(.{
            // Specify the entry point source file relative to build.zig
            .root_source_file = b.path("main.zig"),
            // Target the host machine (the system running the build)
            .target = b.graph.host,
            // Use Debug optimization level (no optimizations, debug symbols included)
            .optimize = .Debug,
        }),
    });
    
    // Register the executable to be installed to the output directory.
    // When `zig build` runs, this artifact will be copied to zig-out/bin/
    b.installArtifact(exe);
}
