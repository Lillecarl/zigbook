const std = @import("std");

/// Build script for log-analyzer project demonstrating native and WASI cross-compilation.
/// Produces two executables: one for native execution and one for WASI runtimes.
pub fn build(b: *std.Build) void {
    // Standard target and optimization options from command-line flags
    // These allow users to specify --target and --optimize when building
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Native executable: optimized for fast runtime performance on the host system
    // This target respects user-specified target and optimization settings
    const exe_native = b.addExecutable(.{
        .name = "log-analyzer-native",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    // Register the native executable for installation to zig-out/bin
    b.installArtifact(exe_native);

    // WASI executable: cross-compiled to WebAssembly with WASI support
    // Uses ReleaseSmall to minimize binary size for portable distribution
    const wasi_target = b.resolveTargetQuery(.{
        .cpu_arch = .wasm32,
        .os_tag = .wasi,
    });
    const exe_wasi = b.addExecutable(.{
        .name = "log-analyzer-wasi",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = wasi_target,
            .optimize = .ReleaseSmall, // Prioritize small binary size over speed
        }),
    });
    // Register the WASI executable for installation to zig-out/bin
    b.installArtifact(exe_wasi);

    // Create run step for native target that executes the compiled binary directly
    const run_native = b.addRunArtifact(exe_native);
    // Ensure the binary is built and installed before attempting to run it
    run_native.step.dependOn(b.getInstallStep());
    // Forward any command-line arguments passed after -- to the executable
    if (b.args) |args| {
        run_native.addArgs(args);
    }
    // Register the run step so users can invoke it with `zig build run-native`
    const run_native_step = b.step("run-native", "Run the native log analyzer");
    run_native_step.dependOn(&run_native.step);

    // Create run step for WASI target with automatic runtime detection
    // First, attempt to detect an available WASI runtime (wasmtime or wasmer)
    const run_wasi = b.addSystemCommand(&.{"echo"});
    const wasi_runtime = detectWasiRuntime(b) orelse {
        // If no runtime is found, provide a helpful error message
        run_wasi.addArg("ERROR: No WASI runtime (wasmtime or wasmer) found in PATH");
        const run_wasi_step = b.step("run-wasi", "Run the WASI log analyzer (requires wasmtime or wasmer)");
        run_wasi_step.dependOn(&run_wasi.step);
        return;
    };

    // Construct the command to run the WASI binary with the detected runtime
    const run_wasi_cmd = b.addSystemCommand(&.{wasi_runtime});
    // Both wasmtime and wasmer require the 'run' subcommand
    if (std.mem.eql(u8, wasi_runtime, "wasmtime") or std.mem.eql(u8, wasi_runtime, "wasmer")) {
        run_wasi_cmd.addArg("run");
        // Grant access to the current directory for file I/O operations
        run_wasi_cmd.addArg("--dir=.");
    }
    // Add the WASI binary as the target to execute
    run_wasi_cmd.addArtifactArg(exe_wasi);
    // Forward user arguments after the -- separator to the WASI program
    if (b.args) |args| {
        run_wasi_cmd.addArg("--");
        run_wasi_cmd.addArgs(args);
    }
    // Ensure the WASI binary is built before attempting to run it
    run_wasi_cmd.step.dependOn(b.getInstallStep());

    // Register the WASI run step so users can invoke it with `zig build run-wasi`
    const run_wasi_step = b.step("run-wasi", "Run the WASI log analyzer (requires wasmtime or wasmer)");
    run_wasi_step.dependOn(&run_wasi_cmd.step);
}

/// Detect available WASI runtime in the system PATH.
/// Checks for wasmtime first, then wasmer as a fallback.
/// Returns the name of the detected runtime, or null if neither is found.
fn detectWasiRuntime(b: *std.Build) ?[]const u8 {
    // Attempt to locate wasmtime using the 'which' command
    var exit_code: u8 = undefined;
    _ = b.runAllowFail(&.{ "which", "wasmtime" }, &exit_code, .Ignore) catch {
        // If wasmtime is not found, try wasmer as a fallback
        _ = b.runAllowFail(&.{ "which", "wasmer" }, &exit_code, .Ignore) catch {
            // Neither runtime was found in PATH
            return null;
        };
        return "wasmer";
    };
    // wasmtime was successfully located
    return "wasmtime";
}
