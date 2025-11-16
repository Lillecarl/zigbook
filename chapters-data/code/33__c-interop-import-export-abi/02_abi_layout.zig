
// Import the Zig standard library for basic functionality
const std = @import("std");

// Import C header file using @cImport to interoperate with C code
// This creates a namespace 'c' containing all declarations from "abi.h"
const c = @cImport({
    @cInclude("abi.h");
});

// Define a Zig struct with 'extern' keyword to match C ABI layout
// The 'extern' keyword ensures the struct uses C-compatible memory layout
// without Zig's automatic padding optimizations
const SensorSample = extern struct {
    temperature_c: f32,  // Temperature reading in Celsius (32-bit float)
    status_bits: u16,    // Status flags packed into 16 bits
    port_id: u8,         // Port identifier (8-bit unsigned)
    reserved: u8 = 0,    // Reserved byte for alignment/future use, default to 0
};

// Convert a C struct to its Zig equivalent using pointer casting
// This demonstrates type-punning between C and Zig representations
// @ptrCast reinterprets the memory layout without copying data
fn fromC(sample: c.struct_SensorSample) SensorSample {
    return @as(*const SensorSample, @ptrCast(&sample)).*;
}

pub fn main() !void {
    // Create a fixed-size buffer for stdout to avoid allocations
    var stdout_buffer: [256]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const out = &stdout_writer.interface;

    // Print size comparison between C and Zig struct representations
    // Both should be identical due to 'extern' struct attribute
    try out.print("sizeof(C struct) = {d}\n", .{@sizeOf(c.struct_SensorSample)});
    try out.print("sizeof(Zig extern struct) = {d}\n", .{@sizeOf(SensorSample)});

    // Call C functions to create sensor samples with specific values
    const left = c.make_sensor_sample(42.5, 0x0102, 7);
    const right = c.make_sensor_sample(38.0, 0x0004, 9);
    
    // Call C function that operates on C structs and returns a computed value
    const total = c.combined_voltage(left, right);

    // Convert C structs to Zig structs for idiomatic Zig access
    const zig_left = fromC(left);
    const zig_right = fromC(right);

    // Print sensor data from the left port with formatted output
    try out.print(
        "left port {d}: {d} status bits, {d:.2} °C\n",
        .{ zig_left.port_id, zig_left.status_bits, zig_left.temperature_c },
    );
    
    // Print sensor data from the right port with formatted output
    try out.print(
        "right port {d}: {d} status bits, {d:.2} °C\n",
        .{ zig_right.port_id, zig_right.status_bits, zig_right.temperature_c },
    );
    
    // Print the combined voltage result computed by C function
    try out.print("combined_voltage = {d:.3}\n", .{total});
    
    // Flush the buffered output to ensure all data is written
    try out.flush();
}
