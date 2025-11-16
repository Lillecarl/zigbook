const std = @import("std");

/// A simple structure representing a sensor device with a numeric reading.
const Sensor = struct {
    reading: i32,
};

/// Prints a sensor's reading value to debug output.
/// Takes a single pointer to a Sensor and displays its current reading.
fn report(label: []const u8, ptr: *Sensor) void {
    std.debug.print("{s} -> reading {d}\n", .{ label, ptr.reading });
}

/// Demonstrates pointer fundamentals, optional pointers, and many-item pointers in Zig.
/// This example covers:
/// - Single-item pointers (*T) and pointer dereferencing
/// - Pointer aliasing and mutation through aliases
/// - Optional pointers (?*T) for representing nullable references
/// - Unwrapping optional pointers with if statements
/// - Many-item pointers ([*]T) for unchecked multi-element access
/// - Converting slices to many-item pointers via .ptr property
pub fn main() !void {
    // Create a sensor instance on the stack
    var sensor = Sensor{ .reading = 41 };
    
    // Create a single-item pointer alias to the sensor
    // The & operator takes the address of sensor
    var alias: *Sensor = &sensor;
    
    // Modify the sensor through the pointer alias
    // Zig automatically dereferences pointer fields
    alias.reading += 1;

    report("alias", alias);

    // Declare an optional pointer initialized to null
    // ?*T represents a pointer that may or may not hold a valid address
    var maybe_alias: ?*Sensor = null;
    
    // Attempt to unwrap the optional pointer
    // This branch will not execute because maybe_alias is null
    if (maybe_alias) |pointer| {
        std.debug.print("unexpected pointer: {d}\n", .{pointer.reading});
    } else {
        std.debug.print("optional pointer empty\n", .{});
    }

    // Assign a valid address to the optional pointer
    maybe_alias = &sensor;
    
    // Unwrap and use the optional pointer
    // The |pointer| capture syntax extracts the non-null value
    if (maybe_alias) |pointer| {
        pointer.reading += 10;
        std.debug.print("optional pointer mutated to {d}\n", .{sensor.reading});
    }

    // Create an array and a slice view of it
    var samples = [_]i32{ 5, 7, 9, 11 };
    const view: []i32 = samples[0..];
    
    // Extract a many-item pointer from the slice
    // Many-item pointers ([*]T) allow unchecked indexing without length tracking
    const many: [*]i32 = view.ptr;
    
    // Modify the underlying array through the many-item pointer
    // No bounds checking is performed at this point
    many[2] = 42;

    std.debug.print("slice view len={}\n", .{view.len});
    // Verify that the modification through many-item pointer affected the original array
    std.debug.print("samples[2] via many pointer = {d}\n", .{samples[2]});
}
