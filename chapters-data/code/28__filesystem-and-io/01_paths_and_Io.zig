const std = @import("std");

pub fn main() !void {
    // Initialize a general-purpose allocator for dynamic memory allocation
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Create a working directory for filesystem operations
    const dir_name = "fs_walkthrough";
    try std.fs.cwd().makePath(dir_name);
    // Clean up the directory on exit, ignoring errors if it doesn't exist
    defer std.fs.cwd().deleteTree(dir_name) catch {};

    // Construct a platform-neutral path by joining directory and filename
    const file_path = try std.fs.path.join(allocator, &.{ dir_name, "metrics.log" });
    defer allocator.free(file_path);

    // Create a new file with truncate and read permissions
    // truncate ensures we start with an empty file
    var file = try std.fs.cwd().createFile(file_path, .{ .truncate = true, .read = true });
    defer file.close();

    // Set up a buffered writer for efficient file I/O
    // The buffer reduces syscall overhead by batching writes
    var file_writer_buffer: [256]u8 = undefined;
    var file_writer_state = file.writer(&file_writer_buffer);
    const file_writer = &file_writer_state.interface;

    // Write CSV data to the file via the buffered writer
    try file_writer.print("timestamp,value\n", .{});
    try file_writer.print("2025-11-05T09:00Z,42\n", .{});
    try file_writer.print("2025-11-05T09:05Z,47\n", .{});
    // Flush ensures all buffered data is written to disk
    try file_writer.flush();

    // Resolve the relative path to an absolute filesystem path
    const absolute_path = try std.fs.cwd().realpathAlloc(allocator, file_path);
    defer allocator.free(absolute_path);

    // Rewind the file cursor to the beginning to read back what we wrote
    try file.seekTo(0);
    // Read the entire file contents into allocated memory (max 16 KiB)
    const contents = try file.readToEndAlloc(allocator, 16 * 1024);
    defer allocator.free(contents);

    // Extract filename and directory components from the path
    const file_name = std.fs.path.basename(file_path);
    const dir_part = std.fs.path.dirname(file_path) orelse ".";

    // Set up a buffered stdout writer following Zig 0.15.2 best practices
    // Buffering stdout improves performance for multiple print calls
    var stdout_buffer: [512]u8 = undefined;
    var stdout_state = std.fs.File.stdout().writer(&stdout_buffer);
    const out = &stdout_state.interface;

    // Display file metadata and contents to stdout
    try out.print("file name: {s}\n", .{file_name});
    try out.print("directory: {s}\n", .{dir_part});
    try out.print("absolute path: {s}\n", .{absolute_path});
    try out.print("--- file contents ---\n{s}", .{contents});
    // Flush the stdout buffer to ensure all output is displayed
    try out.flush();
}
