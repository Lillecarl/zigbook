// Import the Zig standard library for allocator, sorting, debugging, etc.
const std = @import("std");

const Order = std.math.Order;

// A single latency measurement for an endpoint.
// Fields:
//  - endpoint: UTF-8 byte slice identifying the endpoint.
//  - duration_ms: observed latency in milliseconds.
//  - payload_bytes: size of the request/response payload in bytes.
const LatencySample = struct {
    endpoint: []const u8,
    duration_ms: u32,
    payload_bytes: u32,
};

// Compute a score for a latency sample.
// Higher scores represent more severe (worse) samples. The formula favors
// larger durations and applies a small penalty for larger payloads to reduce
// noisy high-latency large-payload samples.
//
// Returns an f64 so scores can be compared with fractional penalties.
fn score(sample: LatencySample) f64 {
    // Convert integers to floating point explicitly to avoid implicit casts.
    // The penalty factor 0.005 was chosen empirically to be small.
    return @as(f64, @floatFromInt(sample.duration_ms)) - (@as(f64, @floatFromInt(sample.payload_bytes)) * 0.005);
}

// TopK is a compile-time generic producer that returns a fixed-capacity,
// score-driven top-K tracker for items of type T.
//
// Parameters:
//  - T: the element type stored in the tracker.
//  - scoreFn: a compile-time function that maps T -> f64 used to rank elements.
fn TopK(comptime T: type, comptime scoreFn: fn (T) f64) type {
    const Error = error{InvalidLimit};

    // Comparator helpers used by the PriorityQueue and for sorting snapshots.
    const Comparators = struct {
        // Comparator used by the PriorityQueue. The first parameter is the
        // user-provided context (unused here), hence the underscore name.
        // Returns an Order (Less/Equal/Greater) based on the score function.
        fn heap(_: void, a: T, b: T) Order {
            return std.math.order(scoreFn(a), scoreFn(b));
        }

        // Boolean comparator used by the heap sort to produce descending order.
        // Returns true when `a` should come before `b` (i.e., a has higher score).
        fn desc(_: void, a: T, b: T) bool {
            return scoreFn(a) > scoreFn(b);
        }
    };

    return struct {
        // A priority queue specialized for T using our heap comparator.
        const Heap = std.PriorityQueue(T, void, Comparators.heap);
        const Self = @This();

        heap: Heap,
        limit: usize,

        // Initialize a TopK tracker with the provided allocator and positive limit.
        // Returns Error.InvalidLimit when limit == 0.
        pub fn init(allocator: std.mem.Allocator, limit: usize) Error!Self {
            if (limit == 0) return Error.InvalidLimit;
            return .{ .heap = Heap.init(allocator, {}), .limit = limit };
        }

        // Deinitialize the underlying heap and free its resources.
        pub fn deinit(self: *Self) void {
            self.heap.deinit();
        }

        // Add a single value into the tracker. If adding causes the internal
        // count to exceed `limit`, the priority queue will evict the item it
        // considers lowest priority according to our comparator, keeping the
        // top-K scored items.
        pub fn add(self: *Self, value: T) !void {
            try self.heap.add(value);
            if (self.heap.count() > self.limit) {
                // Evict the lowest-priority element (as defined by Comparators.heap).
                _ = self.heap.remove();
            }
        }

        // Add multiple values from a slice into the tracker.
        // This simply forwards each element to `add`.
        pub fn addSlice(self: *Self, values: []const T) !void {
            for (values) |value| try self.add(value);
        }

        // Produce a snapshot of the current tracked items in descending score order.
        //
        // The snapshot allocates a new array via `allocator` and copies the
        // internal heap's item storage into it. The result is then sorted
        // descending (highest score first) using Comparators.desc.
        //
        // Caller is responsible for freeing the returned slice.
        pub fn snapshotDescending(self: *Self, allocator: std.mem.Allocator) ![]T {
            const count = self.heap.count();
            const out = try allocator.alloc(T, count);
            // Copy the underlying items buffer into the newly allocated array.
            // This creates an independent snapshot so we can sort without mutating the heap.
            @memcpy(out, self.heap.items[0..count]);
            // Sort in-place so the highest-scored items appear first.
            std.sort.heap(T, out, @as(void, {}), Comparators.desc);
            return out;
        }
    };
}

// Example program demonstrating TopK usage with LatencySample.
pub fn main() !void {
    // Create a general-purpose allocator for example allocations.
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Track the top 5 latency samples by computed score.
    var tracker = try TopK(LatencySample, score).init(allocator, 5);
    defer tracker.deinit();

    // Example samples. These are small, stack-allocated literal records.
    const samples = [_]LatencySample{
        .{ .endpoint = "/v1/users", .duration_ms = 122, .payload_bytes = 850 },
        .{ .endpoint = "/v1/orders", .duration_ms = 210, .payload_bytes = 1200 },
        .{ .endpoint = "/v1/users", .duration_ms = 188, .payload_bytes = 640 },
        .{ .endpoint = "/v1/payments", .duration_ms = 305, .payload_bytes = 1500 },
        .{ .endpoint = "/v1/orders", .duration_ms = 154, .payload_bytes = 700 },
        .{ .endpoint = "/v1/ledger", .duration_ms = 420, .payload_bytes = 540 },
        .{ .endpoint = "/v1/users", .duration_ms = 275, .payload_bytes = 980 },
        .{ .endpoint = "/v1/health", .duration_ms = 34, .payload_bytes = 64 },
        .{ .endpoint = "/v1/ledger", .duration_ms = 362, .payload_bytes = 480 },
    };

    // Bulk-add the sample slice into the tracker.
    try tracker.addSlice(&samples);

    // Capture the current top-K samples in descending order and print them.
    const worst = try tracker.snapshotDescending(allocator);
    defer allocator.free(worst);

    std.debug.print("Top latency offenders (descending by score):\n", .{});
    for (worst, 0..) |sample, idx| {
        // Compute the score again for display purposes (identical to the ordering key).
        const computed_score = score(sample);
        std.debug.print(
            "  {d:>2}. {s: <12} latency={d}ms payload={d}B score={d:.2}\n",
            .{ idx + 1, sample.endpoint, sample.duration_ms, sample.payload_bytes, computed_score },
        );
    }
}