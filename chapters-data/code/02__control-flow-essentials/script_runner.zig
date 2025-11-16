// File: chapters-data/code/02__control-flow-essentials/script_runner.zig

// Demonstrates advanced control flow: switch expressions, labeled loops,
// and early termination based on threshold conditions
const std = @import("std");

/// Enumeration of all possible action types in the script processor
const Action = enum { add, skip, threshold, unknown };

/// Represents a single processing step with an associated action and value
const Step = struct {
    tag: Action,
    value: i32,
};

/// Contains the final state after script execution completes or terminates early
const Outcome = struct {
    index: usize, // Step index where processing stopped
    total: i32,   // Accumulated total at termination
};

/// Maps single-character codes to their corresponding Action enum values.
/// Returns .unknown for unrecognized codes to maintain exhaustive handling.
fn mapCode(code: u8) Action {
    return switch (code) {
        'A' => .add,
        'S' => .skip,
        'T' => .threshold,
        else => .unknown,
    };
}

/// Executes a sequence of steps, accumulating values and checking threshold limits.
/// Processing stops early if a threshold step finds the total meets or exceeds the limit.
/// Returns an Outcome containing the stop index and final accumulated total.
fn process(script: []const Step, limit: i32) Outcome {
    // Running accumulator for add operations
    var total: i32 = 0;

    // for-else construct: break provides early termination value, else provides completion value
    const stop = outer: for (script, 0..) |step, index| {
        // Dispatch based on the current step's action type
        switch (step.tag) {
            // Add operation: accumulate the step's value to the running total
            .add => total += step.value,
            // Skip operation: bypass this step without modifying state
            .skip => continue :outer,
            // Threshold check: terminate early if limit is reached or exceeded
            .threshold => {
                if (total >= limit) break :outer Outcome{ .index = index, .total = total };
                // Threshold not met: continue to next step
                continue :outer;
            },
            // Safety assertion: unknown actions should never appear in validated scripts
            .unknown => unreachable,
        }
    } else Outcome{ .index = script.len, .total = total }; // Normal completion after all steps

    return stop;
}

pub fn main() !void {
    // Define a script sequence demonstrating all action types
    const script = [_]Step{
        .{ .tag = mapCode('A'), .value = 2 },  // Add 2 → total: 2
        .{ .tag = mapCode('S'), .value = 0 },  // Skip (no effect)
        .{ .tag = mapCode('A'), .value = 5 },  // Add 5 → total: 7
        .{ .tag = mapCode('T'), .value = 6 },  // Threshold check (7 >= 6: triggers early exit)
        .{ .tag = mapCode('A'), .value = 10 }, // Never executed due to early termination
    };

    // Execute the script with a threshold limit of 6
    const outcome = process(&script, 6);
    
    // Report where execution stopped and the final accumulated value
    std.debug.print(
        "stopped at step {d} with total {d}\n",
        .{ outcome.index, outcome.total },
    );
}
