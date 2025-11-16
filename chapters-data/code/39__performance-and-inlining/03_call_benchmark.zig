const std = @import("std");
const builtin = @import("builtin");

// Number of iterations to run each benchmark variant
const iterations: usize = 5_000_000;

/// A simple mixing function that demonstrates the performance impact of inlining.
/// Uses bit rotation and arithmetic operations to create a non-trivial workload
/// that the optimizer might handle differently based on call modifiers.
fn mix(value: u32) u32 {
    // Rotate left by 7 bits after XORing with a prime-like constant
    const rotated = std.math.rotl(u32, value ^ 0x9e3779b9, 7);
    // Apply additional mixing with wrapping arithmetic to prevent compile-time evaluation
    return rotated *% 0x85eb_ca6b +% 0xc2b2_ae35;
}

/// Runs the mixing function in a tight loop using the specified call modifier.
/// This allows direct comparison of how different inlining strategies affect performance.
fn run(comptime modifier: std.builtin.CallModifier) u32 {
    var acc: u32 = 0;
    var i: usize = 0;
    while (i < iterations) : (i += 1) {
        // The @call builtin lets us explicitly control inlining behavior at the call site
        acc = @call(modifier, mix, .{acc});
    }
    return acc;
}

pub fn main() !void {
    // Benchmark 1: Let the compiler decide whether to inline (default heuristics)
    var timer = try std.time.Timer.start();
    const auto_result = run(.auto);
    const auto_ns = timer.read();

    // Benchmark 2: Force inlining at every call site
    timer = try std.time.Timer.start();
    const inline_result = run(.always_inline);
    const inline_ns = timer.read();

    // Benchmark 3: Prevent inlining, always emit a function call
    timer = try std.time.Timer.start();
    const never_result = run(.never_inline);
    const never_ns = timer.read();

    // Verify all three strategies produce identical results
    std.debug.assert(auto_result == inline_result);
    std.debug.assert(auto_result == never_result);

    // Display the optimization mode and iteration count for reproducibility
    std.debug.print(
        "optimize-mode={s} iterations={}\n",
        .{
            @tagName(builtin.mode),
            iterations,
        },
    );
    // Report timing results for each call modifier
    std.debug.print("auto call   : {d} ns\n", .{auto_ns});
    std.debug.print("always_inline: {d} ns\n", .{inline_ns});
    std.debug.print("never_inline : {d} ns\n", .{never_ns});
}
