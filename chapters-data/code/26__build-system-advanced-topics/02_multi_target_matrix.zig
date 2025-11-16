const std = @import("std");

/// Represents a target/optimization combination in the build matrix
/// Each combo defines a unique build configuration with a descriptive name
const Combo = struct {
    /// Human-readable identifier for this build configuration
    name: []const u8,
    /// Target query specifying the CPU architecture, OS, and ABI
    query: std.Target.Query,
    /// Optimization level (Debug, ReleaseSafe, ReleaseFast, or ReleaseSmall)
    optimize: std.builtin.OptimizeMode,
};

pub fn build(b: *std.Build) void {
    // Define a matrix of target/optimization combinations to build
    // This demonstrates cross-compilation capabilities and optimization strategies
    const combos = [_]Combo{
        // Native build with debug symbols for development
        .{ .name = "native-debug", .query = .{}, .optimize = .Debug },
        // Linux x86_64 build optimized for maximum performance
        .{ .name = "linux-fast", .query = .{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .gnu }, .optimize = .ReleaseFast },
        // WebAssembly build optimized for minimal binary size
        .{ .name = "wasi-small", .query = .{ .cpu_arch = .wasm32, .os_tag = .wasi }, .optimize = .ReleaseSmall },
    };

    // Create a top-level step that builds all target/optimize combinations
    // Users can invoke this with `zig build matrix`
    const matrix_step = b.step("matrix", "Build every target/optimize pair");

    // Track the run step for the first (host) executable to create a sanity check
    var host_run_step: ?*std.Build.Step = null;

    // Iterate through each combo to create and configure build artifacts
    for (combos, 0..) |combo, index| {
        // Resolve the target query into a concrete target specification
        // This validates the query and fills in any unspecified fields with defaults
        const resolved = b.resolveTargetQuery(combo.query);
        
        // Create a module with the resolved target and optimization settings
        // Using createModule allows precise control over compilation parameters
        const module = b.createModule(.{
            .root_source_file = b.path("matrix/app.zig"),
            .target = resolved,
            .optimize = combo.optimize,
        });

        // Create an executable artifact with a unique name for this combo
        // The name includes the combo identifier to distinguish build outputs
        const exe = b.addExecutable(.{
            .name = b.fmt("matrix-{s}", .{combo.name}),
            .root_module = module,
        });

        // Install the executable to zig-out/bin for distribution
        b.installArtifact(exe);
        
        // Add this executable's build step as a dependency of the matrix step
        // This ensures all executables are built when running `zig build matrix`
        matrix_step.dependOn(&exe.step);

        // For the first combo (assumed to be the native/host target),
        // create a run step for quick testing and validation
        if (index == 0) {
            // Create a command to run the host executable
            const run_cmd = b.addRunArtifact(exe);
            
            // Forward any command-line arguments to the executable
            if (b.args) |args| {
                run_cmd.addArgs(args);
            }
            
            // Create a dedicated step for running the host variant
            const run_step = b.step("run-host", "Run host variant for sanity checks");
            run_step.dependOn(&run_cmd.step);
            
            // Store the run step for later use in the matrix step
            host_run_step = run_step;
        }
    }

    // If a host run step was created, add it as a dependency to the matrix step
    // This ensures that building the matrix also runs a sanity check on the host executable
    if (host_run_step) |run_step| {
        matrix_step.dependOn(run_step);
    }
}
