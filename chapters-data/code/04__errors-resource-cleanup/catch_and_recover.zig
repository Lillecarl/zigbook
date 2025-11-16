const std = @import("std");

// Chapter 4 §1.2 – demonstrate how `catch` branches per error to shape
// recovery strategies without losing control-flow clarity.

const ProbeError = error{ Disconnected, Timeout };

fn readProbe(id: usize) ProbeError!u8 {
    return switch (id) {
        0 => 42,
        1 => error.Timeout,
        2 => error.Disconnected,
        else => 88,
    };
}

pub fn main() !void {
    const ids = [_]usize{ 0, 1, 2, 3 };
    var total: u32 = 0;

    probe_loop: for (ids) |id| {
        const raw = readProbe(id) catch |err| handler: {
            switch (err) {
                error.Timeout => {
                    // Timeouts can be softened with a fallback value, allowing
                    // the loop to continue exercising the “recover and proceed” path.
                    std.debug.print("probe {} timed out; using fallback 200\n", .{id});
                    break :handler 200;
                },
                error.Disconnected => {
                    // A disconnected sensor demonstrates the “skip entirely”
                    // recovery branch discussed in the chapter.
                    std.debug.print("probe {} disconnected; skipping sample\n", .{id});
                    continue :probe_loop;
                },
            }
        };

        total += raw;
        std.debug.print("probe {} -> {}\n", .{ id, raw });
    }

    std.debug.print("aggregate total = {}\n", .{total});
}
