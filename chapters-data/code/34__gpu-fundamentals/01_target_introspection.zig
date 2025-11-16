const std = @import("std");
const builtin = @import("builtin");

pub fn main() !void {
    // Query the compile-time target information to inspect the environment
    // this binary is being compiled for (host or cross-compilation target)
    const target = builtin.target;

    // Display basic target information: CPU architecture, OS, and object format
    std.debug.print("host architecture: {s}\n", .{@tagName(target.cpu.arch)});
    std.debug.print("host operating system: {s}\n", .{@tagName(target.os.tag)});
    std.debug.print("default object format: {s}\n", .{@tagName(target.ofmt)});

    // Check if we're compiling for a GPU backend by examining the target CPU architecture.
    // GPU architectures include AMD GCN, NVIDIA PTX variants, and SPIR-V targets.
    const is_gpu_backend = switch (target.cpu.arch) {
        .amdgcn, .nvptx, .nvptx64, .spirv32, .spirv64 => true,
        else => false,
    };
    std.debug.print("compiling as GPU backend: {}\n", .{is_gpu_backend});

    // Import address space types for querying GPU-specific memory capabilities
    const AddressSpace = std.builtin.AddressSpace;
    const Context = AddressSpace.Context;

    // Query whether the target supports GPU-specific address spaces:
    // - shared: memory shared within a workgroup/threadblock
    // - constant: read-only memory optimized for uniform access across threads
    const shared_ok = target.cpu.supportsAddressSpace(AddressSpace.shared, null);
    const constant_ok = target.cpu.supportsAddressSpace(AddressSpace.constant, Context.constant);

    std.debug.print("supports shared address space: {}\n", .{shared_ok});
    std.debug.print("supports constant address space: {}\n", .{constant_ok});

    // Construct a custom target query for SPIR-V 64-bit targeting Vulkan
    const gpa = std.heap.page_allocator;
    const query = std.Target.Query{
        .cpu_arch = .spirv64,
        .os_tag = .vulkan,
        .abi = .none,
    };
    
    // Convert the target query to a triple string (e.g., "spirv64-vulkan")
    const triple = try query.zigTriple(gpa);
    defer gpa.free(triple);
    std.debug.print("example SPIR-V triple: {s}\n", .{triple});
}
