const std = @import("std");

/// Returns a reference to a buffered stdout writer.
/// The buffer and writer are stored in a private struct to persist across calls.
fn stdout() *std.Io.Writer {
    const g = struct {
        // Static buffer for stdout writes—survives function returns
        var buf: [8192]u8 = undefined;
        // Writer wraps stdout with the buffer; created once
        var w = std.fs.File.stdout().writer(&buf);
    };
    // Return pointer to the writer's generic interface
    return &g.w.interface;
}

/// Builds an N×N multiplication table at compile time.
/// Each cell [i][j] holds (i+1) * (j+1) (1-indexed).
fn buildMulTable(comptime N: usize) [N][N]u16 {
    // Declare the result table; will be computed entirely at compile time
    var t: [N][N]u16 = undefined;
    
    // Outer loop: row index (compile-time variable required for inline while)
    comptime var i: usize = 0;
    inline while (i < N) : (i += 1) {
        // Inner loop: column index
        comptime var j: usize = 0;
        inline while (j < N) : (j += 1) {
            // Store (row+1) * (col+1) in the table
            t[i][j] = @intCast((i + 1) * (j + 1));
        }
    }
    // Return the fully populated table as a compile-time constant
    return t;
}

pub fn main() !void {
    // Acquire the buffered stdout writer
    const out = stdout();
    
    // Table dimension (classic 12×12 times table)
    const N = 12;
    
    // Generate the multiplication table at compile time
    const T = buildMulTable(N);

    // Print header line
    try out.print("{s}x{s} multiplication table (partial):\n", .{ "12", "12" });
    
    // Print only first 6 rows to keep output concise (runtime loop)
    var i: usize = 0;
    while (i < 6) : (i += 1) {
        // Print all 12 columns for this row
        var j: usize = 0;
        while (j < N) : (j += 1) {
            // Format each cell right-aligned in a 4-character field
            try out.print("{d: >4}", .{T[i][j]});
        }
        // End the row with a newline
        try out.print("\n", .{});
    }

    // Flush the buffered writer to ensure all output appears
    try out.flush();
}
