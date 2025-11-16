
// Import the standard library for core utilities
const std = @import("std");

// Type aliases for commonly used types
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList(u8);

/// A dynamic string builder that efficiently constructs strings by appending text.
/// Tracks memory growth events to help understand allocation patterns.
pub const StringBuilder = struct {
    allocator: Allocator,
    list: ArrayList = ArrayList.empty,
    /// Counter for tracking how many times the underlying buffer has grown
    growth_events: usize = 0,

    /// Writer interface compatible with std.io.Writer for formatted output
    pub const Writer = std.io.GenericWriter(*StringBuilder, Allocator.Error, writeFn);

    /// Creates a new StringBuilder with no initial capacity
    pub fn init(allocator: Allocator) StringBuilder {
        return .{
            .allocator = allocator,
            .list = ArrayList.empty,
            .growth_events = 0,
        };
    }

    /// Creates a new StringBuilder with a pre-allocated capacity to reduce reallocations
    pub fn initCapacity(allocator: Allocator, initial_capacity: usize) Allocator.Error!StringBuilder {
        var list = ArrayList.empty;
        // Allocate exact capacity upfront to avoid initial growth events
        try list.ensureTotalCapacityPrecise(allocator, initial_capacity);
        return .{
            .allocator = allocator,
            .list = list,
            .growth_events = 0,
        };
    }

    /// Frees all allocated memory
    pub fn deinit(self: *StringBuilder) void {
        self.list.deinit(self.allocator);
    }

    /// Internal helper to detect and count capacity changes
    fn trackGrowth(self: *StringBuilder, prev_capacity: usize) void {
        if (self.list.capacity != prev_capacity) {
            self.growth_events += 1;
        }
    }

    /// Appends a text slice to the builder
    pub fn append(self: *StringBuilder, text: []const u8) Allocator.Error!void {
        const before = self.list.capacity;
        try self.list.appendSlice(self.allocator, text);
        self.trackGrowth(before);
    }

    /// Appends a single byte to the builder
    pub fn appendByte(self: *StringBuilder, byte: u8) Allocator.Error!void {
        const before = self.list.capacity;
        try self.list.append(self.allocator, byte);
        self.trackGrowth(before);
    }

    /// Ensures the builder has space for at least 'additional' more bytes without reallocation
    pub fn ensureUnusedCapacity(self: *StringBuilder, additional: usize) Allocator.Error!void {
        const before = self.list.capacity;
        try self.list.ensureUnusedCapacity(self.allocator, additional);
        self.trackGrowth(before);
    }

    /// Returns a Writer interface for use with formatting functions like std.fmt.format
    pub fn writer(self: *StringBuilder) Writer {
        return .{ .context = self };
    }

    /// Internal write function that implements the Writer interface
    fn writeFn(self: *StringBuilder, chunk: []const u8) Allocator.Error!usize {
        try self.append(chunk);
        return chunk.len;
    }

    /// Clears the content while keeping allocated capacity for reuse
    pub fn reset(self: *StringBuilder) void {
        self.list.clearRetainingCapacity();
        self.growth_events = 0;
    }

    /// Transfers ownership of the built string to the caller, resetting the builder
    pub fn toOwnedSlice(self: *StringBuilder) Allocator.Error![]u8 {
        return try self.list.toOwnedSlice(self.allocator);
    }

    /// Returns current statistics about the builder's state without modifying it
    pub fn snapshot(self: *const StringBuilder) Stats {
        return .{
            .length = self.list.items.len,
            .capacity = self.list.capacity,
            .growth_events = self.growth_events,
        };
    }
};

/// Statistics snapshot of a StringBuilder's current state
pub const Stats = struct {
    length: usize,
    capacity: usize,
    growth_events: usize,

    /// Custom formatter for displaying stats in a readable format
    pub fn format(self: Stats, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        try writer.print("len={d} cap={d} growths={d}", .{ self.length, self.capacity, self.growth_events });
    }
};
