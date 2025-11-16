/// Demo: Using std.PriorityQueue to dispatch tasks by priority.
/// Lower urgency values mean higher priority; ties are broken by earlier submission time.
/// This example prints the order in which tasks would be processed.
///
/// Notes:
/// - The comparator returns `.lt` when `a` should be dispatched before `b`.
/// - We also order by `submitted_at_ms` to ensure deterministic order among equal urgencies.
const std = @import("std");
const Order = std.math.Order;

/// A single work item to schedule.
const Task = struct {
    /// Display name for the task.
    name: []const u8,
    /// Priority indicator: lower value = more urgent.
    urgency: u8,
    /// Monotonic timestamp in milliseconds used to break ties (earlier wins).
    submitted_at_ms: u64,
};

/// Comparator for the priority queue:
/// - Primary key: urgency (lower is dispatched first)
/// - Secondary key: submitted_at_ms (earlier is dispatched first)
fn taskOrder(_: void, a: Task, b: Task) Order {
    // Compare by urgency first.
    if (a.urgency < b.urgency) return .lt;
    if (a.urgency > b.urgency) return .gt;

    // Tie-breaker: earlier submission is higher priority.
    return std.math.order(a.submitted_at_ms, b.submitted_at_ms);
}

/// Program entry: builds a priority queue and prints dispatch order.
pub fn main() !void {
    // Use the General Purpose Allocator (GPA) for simplicity in examples.
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Instantiate a priority queue of Task:
    // - Context type is `void` (no extra state needed by the comparator)
    // - `taskOrder` defines the ordering.
    var queue = std.PriorityQueue(Task, void, taskOrder).init(allocator, {});
    defer queue.deinit();

    // Enqueue tasks with varying urgency and submission times.
    // Expectation (by our ordering): lower urgency processed first;
    // within same urgency, earlier submitted_at_ms processed first.
    try queue.add(.{ .name = "compile pointer.zig", .urgency = 0, .submitted_at_ms = 1 });
    try queue.add(.{ .name = "run tests", .urgency = 1, .submitted_at_ms = 2 });
    try queue.add(.{ .name = "deploy preview", .urgency = 2, .submitted_at_ms = 3 });
    try queue.add(.{ .name = "prepare changelog", .urgency = 1, .submitted_at_ms = 4 });

    std.debug.print("Dispatch order:\n", .{});

    // Remove tasks in priority order until the queue is empty.
    // removeOrNull() yields the next Task or null when empty.
    while (queue.removeOrNull()) |task| {
        std.debug.print("  - {s} (urgency {d})\n", .{ task.name, task.urgency });
    }
}
