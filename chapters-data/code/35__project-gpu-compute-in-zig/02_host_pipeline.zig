// Project host pipeline for the vector-square kernel.
//
// This program demonstrates the CPU orchestration that pairs with the
// `squareVector` SPIR-V kernel. It prepares input data, plans a dispatch,
// validates the compiled shader module, and runs a CPU fallback that mirrors the
// GPU algorithm. When requested via `--emit-binary`, it also writes the CPU
// output to `out/reference.bin` so external GPU runs can be compared bit-for-bit.

const std = @import("std");

/// Must match `lane_capacity` in 01_vector_square_kernel.zig.
const lane_capacity: u32 = 1024;
const default_problem_len: u32 = 1000;
const workgroup_size: u32 = 64;
const spirv_path = "kernels/vector_square.spv";
const gpu_dump_path = "out/gpu_result.bin";
const cpu_dump_path = "out/reference.bin";

/// Encapsulates the GPU workgroup dispatch geometry, accounting for padding
/// when the total workload doesn't evenly divide into workgroup boundaries.
const DispatchPlan = struct {
    workgroup_size: u32,
    group_count: u32,
    /// Total invocations including padding to fill complete workgroups
    padded_invocations: u32,
    /// Number of unused lanes in the final workgroup
    tail: u32,
};

/// Tracks a validated SPIR-V module alongside its filesystem path for diagnostics.
const ModuleInfo = struct {
    path: []const u8,
    bytes: []u8,
};

pub fn main() !void {
    // Initialize allocator with leak detection for development builds
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer switch (gpa.deinit()) {
        .ok => {},
        .leak => std.log.err("general-purpose allocator detected a leak", .{}),
    };
    const allocator = gpa.allocator();

    // Parse command-line arguments for optional flags
    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();
    _ = args.next(); // skip program name

    var emit_binary = false;
    var logical_len: u32 = default_problem_len;

    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--emit-binary")) {
            emit_binary = true;
        } else if (std.mem.eql(u8, arg, "--length")) {
            const value = args.next() orelse return error.MissingLengthValue;
            logical_len = try std.fmt.parseInt(u32, value, 10);
        } else {
            return error.UnknownFlag;
        }
    }

    // Clamp user-provided length to prevent buffer overruns in the kernel
    if (logical_len == 0 or logical_len > lane_capacity) {
        std.log.warn("clamping problem length to lane capacity ({d})", .{lane_capacity});
        logical_len = @min(lane_capacity, logical_len);
        if (logical_len == 0) logical_len = @min(lane_capacity, default_problem_len);
    }

    // Calculate how many workgroups we need to process this many elements
    const plan = computeDispatch(logical_len, workgroup_size);
    std.debug.print(
        "launch plan: {d} groups × {d} lanes => {d} invocations (tail {d})\n",
        .{ plan.group_count, plan.workgroup_size, plan.padded_invocations, plan.tail },
    );

    // Use deterministic PRNG for reproducible test runs across environments
    var prng = std.Random.DefaultPrng.init(0xBEEFFACE);
    const random = prng.random();

    // Generate input data with a predictable pattern plus random noise
    var input = try allocator.alloc(f32, logical_len);
    defer allocator.free(input);
    for (input, 0..input.len) |*slot, idx| {
        const base: f32 = @floatFromInt(idx);
        slot.* = base * 0.5 + random.float(f32);
    }

    // Execute CPU reference implementation to produce expected results
    var cpu_output = try allocator.alloc(f32, logical_len);
    defer allocator.free(cpu_output);
    runCpuFallback(input, cpu_output);

    // Compute simple checksum for quick sanity verification
    const checksum = checksumSlice(cpu_output);
    std.debug.print("cpu fallback checksum: {d:.6}\n", .{checksum});

    // Attempt to load and validate the compiled SPIR-V shader module
    const module = try loadSpirvIfPresent(allocator, spirv_path);
    defer if (module) |info| allocator.free(info.bytes);

    if (module) |info| {
        std.debug.print(
            "gpu module: {s} ({d} bytes, header ok)\n",
            .{ info.path, info.bytes.len },
        );
    } else {
        std.debug.print(
            "gpu module: missing ({s}); run kernel build command to generate it\n",
            .{spirv_path},
        );
    }

    // Check if a GPU execution captured output for comparison
    const maybe_gpu_dump = try loadBinaryIfPresent(allocator, gpu_dump_path);
    defer if (maybe_gpu_dump) |blob| allocator.free(blob);

    if (maybe_gpu_dump) |blob| {
        // Compare GPU results against CPU reference lane-by-lane
        const mismatches = compareF32Slices(cpu_output, blob);
        std.debug.print(
            "gpu capture diff: {d} mismatched lanes\n",
            .{mismatches},
        );
    } else {
        std.debug.print(
            "gpu capture diff: skipped (no {s} file found)\n",
            .{gpu_dump_path},
        );
    }

    // Display first few lanes for manual inspection
    const sample_count = @min(input.len, 6);
    for (input[0..sample_count], cpu_output[0..sample_count], 0..) |original, squared, idx| {
        std.debug.print(
            "lane {d:>3}: in={d:.5} out={d:.5}\n",
            .{ idx, original, squared },
        );
    }

    // Write reference dump if requested for external GPU validation tools
    if (emit_binary) {
        try emitCpuDump(cpu_output);
        std.debug.print("cpu reference written to {s}\n", .{cpu_dump_path});
    }
}

/// Computes dispatch geometry by rounding up to complete workgroups.
/// Returns the number of groups, total padded invocations, and unused tail lanes.
fn computeDispatch(total_items: u32, group_size: u32) DispatchPlan {
    std.debug.assert(group_size > 0);
    // Divide ceiling to ensure all items are covered
    const groups = std.math.divCeil(u32, total_items, group_size) catch unreachable;
    const padded = groups * group_size;
    return .{
        .workgroup_size = group_size,
        .group_count = groups,
        .padded_invocations = padded,
        .tail = padded - total_items,
    };
}

/// Executes the squaring operation on the CPU, mirroring the GPU kernel logic.
/// Each output element is the square of its corresponding input.
fn runCpuFallback(input: []const f32, output: []f32) void {
    std.debug.assert(input.len == output.len);
    for (input, output) |value, *slot| {
        slot.* = value * value;
    }
}

/// Calculates a simple sum of all f32 values in double precision for observability.
fn checksumSlice(values: []const f32) f64 {
    var total: f64 = 0.0;
    for (values) |value| {
        total += @as(f64, @floatCast(value));
    }
    return total;
}

/// Attempts to read and validate a SPIR-V binary module from disk.
/// Returns null if the file doesn't exist; validates the magic number (0x07230203).
fn loadSpirvIfPresent(allocator: std.mem.Allocator, path: []const u8) !?ModuleInfo {
    var file = std.fs.cwd().openFile(path, .{}) catch |err| switch (err) {
        error.FileNotFound => return null,
        else => return err,
    };
    defer file.close();

    const bytes = try file.readToEndAlloc(allocator, 1 << 20);
    errdefer allocator.free(bytes);

    // Validate minimum size for SPIR-V header
    if (bytes.len < 4) return error.SpirvTooSmall;
    // Check little-endian magic number
    const magic = std.mem.readInt(u32, bytes[0..4], .little);
    if (magic != 0x0723_0203) return error.InvalidSpirvMagic;

    return ModuleInfo{ .path = path, .bytes = bytes };
}

/// Loads raw binary data if the file exists; returns null for missing files.
fn loadBinaryIfPresent(allocator: std.mem.Allocator, path: []const u8) !?[]u8 {
    var file = std.fs.cwd().openFile(path, .{}) catch |err| switch (err) {
        error.FileNotFound => return null,
        else => return err,
    };
    defer file.close();
    const bytes = try file.readToEndAlloc(allocator, 1 << 24);
    return bytes;
}

/// Compares two f32 slices for approximate equality within 1e-6 tolerance.
/// Returns the count of mismatched lanes; returns expected.len if sizes differ.
fn compareF32Slices(expected: []const f32, blob_bytes: []const u8) usize {
    // Ensure blob size aligns with f32 boundaries
    if (blob_bytes.len % @sizeOf(f32) != 0) return expected.len;
    const actual = std.mem.bytesAsSlice(f32, blob_bytes);
    if (actual.len != expected.len) return expected.len;

    var mismatches: usize = 0;
    for (expected, actual) |lhs, rhs| {
        // Use floating-point tolerance to account for minor GPU precision differences
        if (!std.math.approxEqAbs(f32, lhs, rhs, 1e-6)) {
            mismatches += 1;
        }
    }
    return mismatches;
}

/// Writes CPU-computed f32 array to disk as raw bytes for external comparison tools.
fn emitCpuDump(values: []const f32) !void {
    // Ensure output directory exists before writing
    try std.fs.cwd().makePath("out");
    var file = try std.fs.cwd().createFile(cpu_dump_path, .{ .truncate = true });
    defer file.close();
    // Convert f32 slice to raw bytes for binary serialization
    const bytes = std.mem.sliceAsBytes(values);
    try file.writeAll(bytes);
}
