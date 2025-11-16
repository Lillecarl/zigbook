//! GPU Kernel: Coordinate Capture
//!
//! This module demonstrates a minimal SPIR-V compute kernel that captures GPU dispatch
//! coordinates into a storage buffer. It shows how to use Zig's GPU-specific builtins
//! and address space annotations to write kernels that compile to SPIR-V.

const builtin = @import("builtin");

/// Represents GPU dispatch coordinates for a single invocation
/// 
/// Uses `extern` layout to guarantee memory layout matches host-side expectations,
/// ensuring the kernel's output can be safely interpreted by CPU code reading the buffer.
const Coordinates = extern struct {
    /// Work group ID (which group this invocation belongs to)
    group: u32,
    /// Work group size (number of invocations per group in this dimension)
    group_size: u32,
    /// Local invocation ID within the work group (0 to group_size-1)
    local: u32,
    /// Global linear ID across all invocations (group * group_size + local)
    linear: u32,
};

/// GPU kernel entry point that captures dispatch coordinates
///
/// This function must be exported so the SPIR-V compiler generates an entry point.
/// The `callconv(.kernel)` calling convention tells Zig to emit GPU-specific function
/// attributes and handle parameter passing according to compute shader ABI.
///
/// Parameters:
///   - out: Pointer to storage buffer where coordinates will be written.
///          The `.storage_buffer` address space annotation ensures proper
///          memory access patterns for device-visible GPU memory.
pub export fn captureCoordinates(out: *addrspace(.storage_buffer) Coordinates) callconv(.kernel) void {
    // Query the work group ID in the X dimension (first dimension)
    // @workGroupId is a GPU-specific builtin that returns the current work group's coordinate
    const group = @workGroupId(0);
    
    // Query the work group size (how many invocations per group in this dimension)
    // This is set at dispatch time by the host and queried here for completeness
    const group_size = @workGroupSize(0);
    
    // Query the local invocation ID within this work group (0 to group_size-1)
    // @workItemId is the per-work-group thread index
    const local = @workItemId(0);
    
    // Calculate global linear index across all invocations
    // This formula converts 2D coordinates (group, local) to a flat 1D index
    const linear = group * group_size + local;

    // Write all captured coordinates to the output buffer
    // The GPU will ensure this write is visible to the host after synchronization
    out.* = .{
        .group = group,
        .group_size = group_size,
        .local = local,
        .linear = linear,
    };
}

// Compile-time validation to ensure this module is only compiled for SPIR-V targets
// This prevents accidental compilation for CPU architectures where GPU builtins are unavailable
comptime {
    switch (builtin.target.cpu.arch) {
        // Accept both 32-bit and 64-bit SPIR-V architectures
        .spirv32, .spirv64 => {},
        // Reject all other architectures with a helpful error message
        else => @compileError("captureCoordinates must be compiled with a SPIR-V target, e.g. -target spirv32-vulkan-none"),
    }
}
