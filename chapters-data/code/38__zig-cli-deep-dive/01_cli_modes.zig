const std = @import("std");
const builtin = @import("builtin");

pub fn main() !void {
    // Set up a general-purpose allocator for dynamic memory allocation
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();
    
    // Retrieve all command-line arguments passed to the program
    const argv = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, argv);

    // Display the optimization mode used during compilation (Debug, ReleaseSafe, ReleaseFast, ReleaseSmall)
    std.debug.print("optimize-mode: {s}\n", .{@tagName(builtin.mode)});
    
    // Display the target platform triple (architecture-os-abi)
    std.debug.print(
        "target-triple: {s}-{s}-{s}\n",
        .{
            @tagName(builtin.target.cpu.arch),
            @tagName(builtin.target.os.tag),
            @tagName(builtin.target.abi),
        },
    );
    
    // Display whether the program was compiled in single-threaded mode
    std.debug.print("single-threaded: {}\n", .{builtin.single_threaded});

    // Check if any user arguments were provided (argv[0] is the program name itself)
    if (argv.len <= 1) {
        std.debug.print("user-args: <none>\n", .{});
        return;
    }

    // Print all user-provided arguments (skipping the program name at argv[0])
    std.debug.print("user-args:\n", .{});
    for (argv[1..], 0..) |arg, idx| {
        std.debug.print("  arg[{d}] = {s}\n", .{ idx, arg });
    }
}
