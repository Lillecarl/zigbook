//! SPIR-V Kernel: element-wise vector squaring
//!
//! This kernel expects three storage buffers: an input vector (`in_values`), an
//! output vector (`out_values`), and a descriptor struct `Submission` that
//! communicates the logical element count. Each invocation squares one element
//! and writes the result back to `out_values`.

const builtin = @import("builtin");

/// Maximum number of elements the kernel will touch.
pub const lane_capacity: u32 = 1024;

/// Submission header shared between the host and the kernel.
///
/// The `extern` layout ensures the struct matches bindings created by Vulkan or
/// WebGPU descriptor tables.
const Submission = extern struct {
    /// Logical element count requested by the host.
    len: u32,
    _padding: u32 = 0,
};

/// Storage buffer layout expected by the kernel.
const VectorPayload = extern struct {
    values: [lane_capacity]f32,
};

/// Squares each element of `in_values` and writes the result to `out_values`.
///
/// The kernel is written defensively: it checks both the logical length passed
/// by the host and the static `lane_capacity` to avoid out-of-bounds writes when
/// dispatched with more threads than necessary.
pub export fn squareVector(
    submission: *addrspace(.storage_buffer) const Submission,
    in_values: *addrspace(.storage_buffer) const VectorPayload,
    out_values: *addrspace(.storage_buffer) VectorPayload,
) callconv(.kernel) void {
    const group_index = @workGroupId(0);
    const group_width = @workGroupSize(0);
    const local_index = @workItemId(0);
    const linear = group_index * group_width + local_index;

    const logical_len = submission.len;
    if (linear >= logical_len or linear >= lane_capacity) return;

    const value = in_values.*.values[linear];
    out_values.*.values[linear] = value * value;
}

// Guard compilation so this file is only compiled when targeting SPIR-V.
comptime {
    switch (builtin.target.cpu.arch) {
        .spirv32, .spirv64 => {},
        else => @compileError("squareVector must be compiled with a SPIR-V target, e.g. -target spirv32-vulkan-none"),
    }
}
