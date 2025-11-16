const std = @import("std");
const analysis = @import("analysis.zig");

pub fn main() !void {
    // Initialize general-purpose allocator for dynamic memory allocation
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Parse command-line arguments into an allocated slice
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    // Check for optional --input flag to specify a file path
    var input_path: ?[]const u8 = null;
    var i: usize = 1; // Skip program name at args[0]
    while (i < args.len) : (i += 1) {
        if (std.mem.eql(u8, args[i], "--input")) {
            i += 1;
            if (i < args.len) {
                input_path = args[i];
            } else {
                std.debug.print("ERROR: --input requires a file path\n", .{});
                return error.MissingArgument;
            }
        }
    }

    // Read input content from either file or stdin
    // Using labeled blocks to unify type across both branches
    const content = if (input_path) |path| blk: {
        std.debug.print("analyzing: {s}\n", .{path});
        // Read entire file content with 10MB limit
        break :blk try std.fs.cwd().readFileAlloc(allocator, path, 10 * 1024 * 1024);
    } else blk: {
        std.debug.print("analyzing: stdin\n", .{});
        // Construct File handle directly from stdin file descriptor
        const stdin = std.fs.File{ .handle = std.posix.STDIN_FILENO };
        // Read all available stdin data with same 10MB limit
        break :blk try stdin.readToEndAlloc(allocator, 10 * 1024 * 1024);
    };
    defer allocator.free(content);

    // Delegate log analysis to the analysis module
    const stats = analysis.analyzeLog(content);
    
    // Print summary statistics to stderr (std.debug.print)
    std.debug.print("results: INFO={d} WARN={d} ERROR={d}\n", .{
        stats.info_count,
        stats.warn_count,
        stats.error_count,
    });
}
