//! GPU Dispatch Planning Utility
//! 
//! This module demonstrates how to calculate workgroup dispatch parameters for GPU compute shaders.
//! It shows the relationship between total work items, workgroup size, and the resulting dispatch
//! configuration, including handling of "tail" elements that don't fill a complete workgroup.

const std = @import("std");

/// Represents a complete dispatch configuration for parallel execution
/// Contains all necessary parameters to launch a compute kernel or parallel task
const DispatchPlan = struct {
    /// Size of each workgroup (number of threads/invocations per group)
    workgroup_size: u32,
    /// Number of workgroups needed to cover all items
    group_count: u32,
    /// Total invocations including padding (always a multiple of workgroup_size)
    padded_invocations: u32,
    /// Number of padded/unused invocations in the last workgroup
    tail: u32,
};

/// Computes optimal dispatch parameters for a given problem size and workgroup configuration
/// 
/// Calculates how many workgroups are needed to process all items, accounting for the fact
/// that the last workgroup may be partially filled. This is essential for GPU compute shaders
/// where work must be dispatched in multiples of the workgroup size.
fn computeDispatch(total_items: u32, workgroup_size: u32) DispatchPlan {
    // Ensure workgroup size is valid (GPU workgroups cannot be empty)
    std.debug.assert(workgroup_size > 0);
    
    // Calculate number of workgroups needed, rounding up to ensure all items are covered
    const groups = std.math.divCeil(u32, total_items, workgroup_size) catch unreachable;
    
    // Calculate total invocations including padding (GPU always launches complete workgroups)
    const padded = groups * workgroup_size;
    
    return .{
        .workgroup_size = workgroup_size,
        .group_count = groups,
        .padded_invocations = padded,
        // Tail represents wasted invocations that must be handled with bounds checks
        .tail = padded - total_items,
    };
}

/// Simulates CPU-side parallel execution planning using the same dispatch logic
/// 
/// Demonstrates that the workgroup dispatch formula applies equally to CPU thread batching,
/// ensuring consistent behavior between GPU and CPU fallback implementations.
fn simulateCpuFallback(total_items: u32, lanes: u32) DispatchPlan {
    // Reuse the GPU formula so host-side chunking matches device scheduling.
    return computeDispatch(total_items, lanes);
}

pub fn main() !void {
    // Define a sample problem: processing 1000 items
    const problem_size: u32 = 1000;
    
    // Typical GPU workgroup size (often 32, 64, or 256 depending on hardware)
    const workgroup_size: u32 = 64;
    
    // Calculate GPU dispatch configuration
    const plan = computeDispatch(problem_size, workgroup_size);
    std.debug.print(
        "gpu dispatch: {d} groups × {d} lanes => {d} invocations (tail {d})\n",
        .{ plan.group_count, plan.workgroup_size, plan.padded_invocations, plan.tail },
    );

    // Simulate CPU fallback with fewer parallel lanes
    const fallback_threads: u32 = 16;
    const cpu = simulateCpuFallback(problem_size, fallback_threads);
    std.debug.print(
        "cpu chunks: {d} batches × {d} lanes => {d} logical tasks (tail {d})\n",
        .{ cpu.group_count, cpu.workgroup_size, cpu.padded_invocations, cpu.tail },
    );
}
