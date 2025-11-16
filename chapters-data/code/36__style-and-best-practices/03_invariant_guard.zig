//! Maintainability checklist example with an internal invariant helper.
//!
//! This module demonstrates defensive programming practices by implementing
//! a ring buffer data structure that validates its internal state invariants
//! before and after mutating operations.

const std = @import("std");

/// A fixed-capacity circular buffer that stores i32 values.
/// The buffer wraps around when full, and uses modular arithmetic
/// to implement FIFO (First-In-First-Out) semantics.
pub const RingBuffer = struct {
    storage: []i32,
    head: usize = 0,      // Index of the first element
    count: usize = 0,     // Number of elements currently stored

    /// Errors that can occur during ring buffer operations.
    pub const Error = error{Overflow};

    /// Creates a new RingBuffer backed by the provided storage slice.
    /// The caller retains ownership of the storage memory.
    pub fn init(storage: []i32) RingBuffer {
        return .{ .storage = storage };
    }

    /// Validates internal state consistency.
    /// This is called before and after mutations to catch logic errors early.
    /// Checks that:
    /// - Empty storage implies zero head and count
    /// - Head index is within storage bounds
    /// - Count doesn't exceed storage capacity
    fn invariant(self: *const RingBuffer) void {
        if (self.storage.len == 0) {
            std.debug.assert(self.head == 0);
            std.debug.assert(self.count == 0);
            return;
        }

        std.debug.assert(self.head < self.storage.len);
        std.debug.assert(self.count <= self.storage.len);
    }

    /// Adds a value to the end of the buffer.
    /// Returns Error.Overflow if the buffer is at capacity or has no storage.
    /// Invariants are checked before and after the operation.
    pub fn push(self: *RingBuffer, value: i32) Error!void {
        self.invariant();
        if (self.storage.len == 0 or self.count == self.storage.len) return Error.Overflow;

        // Calculate the insertion position using circular indexing
        const index = (self.head + self.count) % self.storage.len;
        self.storage[index] = value;
        self.count += 1;
        self.invariant();
    }

    /// Removes and returns the oldest value from the buffer.
    /// Returns null if the buffer is empty.
    /// Advances the head pointer circularly and decrements the count.
    pub fn pop(self: *RingBuffer) ?i32 {
        self.invariant();
        if (self.count == 0) return null;

        const value = self.storage[self.head];
        // Move head forward circularly
        self.head = (self.head + 1) % self.storage.len;
        self.count -= 1;
        self.invariant();
        return value;
    }
};

// Verifies that the buffer correctly rejects pushes when at capacity.
test "ring buffer enforces capacity" {
    var storage = [_]i32{ 0, 0, 0 };
    var buffer = RingBuffer.init(&storage);

    try buffer.push(1);
    try buffer.push(2);
    try buffer.push(3);
    // Fourth push should fail because buffer capacity is 3
    try std.testing.expectError(RingBuffer.Error.Overflow, buffer.push(4));
}

// Verifies that values are retrieved in the same order they were inserted.
test "ring buffer preserves FIFO order" {
    var storage = [_]i32{ 0, 0, 0 };
    var buffer = RingBuffer.init(&storage);

    try buffer.push(10);
    try buffer.push(20);
    try buffer.push(30);

    // Values should come out in insertion order
    try std.testing.expectEqual(@as(?i32, 10), buffer.pop());
    try std.testing.expectEqual(@as(?i32, 20), buffer.pop());
    try std.testing.expectEqual(@as(?i32, 30), buffer.pop());
    // Buffer is now empty, should return null
    try std.testing.expectEqual(@as(?i32, null), buffer.pop());
}
