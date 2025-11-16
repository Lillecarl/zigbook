const std = @import("std");

fn validateAnalyzer(comptime Analyzer: type) void {
    if (!@hasDecl(Analyzer, "State"))
        @compileError("Analyzer must define `pub const State`.");
    const state_alias = @field(Analyzer, "State");
    if (@TypeOf(state_alias) != type)
        @compileError("Analyzer.State must be a type.");

    if (!@hasDecl(Analyzer, "Summary"))
        @compileError("Analyzer must define `pub const Summary`.");
    const summary_alias = @field(Analyzer, "Summary");
    if (@TypeOf(summary_alias) != type)
        @compileError("Analyzer.Summary must be a type.");

    if (!@hasDecl(Analyzer, "init"))
        @compileError("Analyzer missing `pub fn init`.");
    if (!@hasDecl(Analyzer, "observe"))
        @compileError("Analyzer missing `pub fn observe`.");
    if (!@hasDecl(Analyzer, "summarize"))
        @compileError("Analyzer missing `pub fn summarize`.");
}

fn computeReport(comptime Analyzer: type, readings: []const f64) Analyzer.Summary {
    comptime validateAnalyzer(Analyzer);

    var state = Analyzer.init(readings.len);
    for (readings) |value| {
        Analyzer.observe(&state, value);
    }
    return Analyzer.summarize(state);
}

const RangeAnalyzer = struct {
    pub const State = struct {
        min: f64,
        max: f64,
        seen: usize,
    };

    pub const Summary = struct {
        min: f64,
        max: f64,
        spread: f64,
    };

    pub fn init(_: usize) State {
        return .{
            .min = std.math.inf(f64),
            .max = -std.math.inf(f64),
            .seen = 0,
        };
    }

    pub fn observe(state: *State, value: f64) void {
        state.seen += 1;
        state.min = @min(state.min, value);
        state.max = @max(state.max, value);
    }

    pub fn summarize(state: State) Summary {
        if (state.seen == 0) {
            return .{ .min = 0, .max = 0, .spread = 0 };
        }
        return .{
            .min = state.min,
            .max = state.max,
            .spread = state.max - state.min,
        };
    }
};

const MeanVarianceAnalyzer = struct {
    pub const State = struct {
        count: usize,
        sum: f64,
        sum_sq: f64,
    };

    pub const Summary = struct {
        mean: f64,
        variance: f64,
    };

    pub fn init(_: usize) State {
        return .{ .count = 0, .sum = 0, .sum_sq = 0 };
    }

    pub fn observe(state: *State, value: f64) void {
        state.count += 1;
        state.sum += value;
        state.sum_sq += value * value;
    }

    pub fn summarize(state: State) Summary {
        if (state.count == 0) {
            return .{ .mean = 0, .variance = 0 };
        }
        const n = @as(f64, @floatFromInt(state.count));
        const mean = state.sum / n;
        const variance = @max(0.0, state.sum_sq / n - mean * mean);
        return .{ .mean = mean, .variance = variance };
    }
};

pub fn main() !void {
    const readings = [_]f64{ 21.0, 23.5, 22.1, 24.0, 22.9 };

    const range = computeReport(RangeAnalyzer, readings[0..]);
    const stats = computeReport(MeanVarianceAnalyzer, readings[0..]);

    std.debug.print(
        "Range -> min={d:.2} max={d:.2} spread={d:.2}\n",
        .{ range.min, range.max, range.spread },
    );
    std.debug.print(
        "Mean/variance -> mean={d:.2} variance={d:.3}\n",
        .{ stats.mean, stats.variance },
    );
}
