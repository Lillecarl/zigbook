const std = @import("std");

pub fn main() !void {
    // Initialize a general-purpose allocator for dynamic memory allocation
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Create a working directory for the stream copy demonstration
    const dir_name = "fs_stream_copy";
    try std.fs.cwd().makePath(dir_name);
    // Clean up the directory on exit, ignoring errors if it doesn't exist
    defer std.fs.cwd().deleteTree(dir_name) catch {};

    // Construct a platform-neutral path for the source file
    const source_path = try std.fs.path.join(allocator, &.{ dir_name, "source.txt" });
    defer allocator.free(source_path);

    // Create the source file with truncate and read permissions
    // truncate ensures we start with an empty file
    var source_file = try std.fs.cwd().createFile(source_path, .{ .truncate = true, .read = true });
    defer source_file.close();

    // Set up a buffered writer for the source file
    // Buffering reduces syscall overhead by batching writes
    var source_writer_buffer: [128]u8 = undefined;
    var source_writer_state = source_file.writer(&source_writer_buffer);
    const source_writer = &source_writer_state.interface;

    // Write sample data to the source file
    try source_writer.print("alpha\n", .{});
    try source_writer.print("beta\n", .{});
    try source_writer.print("gamma\n", .{});
    // Flush ensures all buffered data is written to disk
    try source_writer.flush();

    // Rewind the source file cursor to the beginning for reading
    try source_file.seekTo(0);

    // Construct a platform-neutral path for the destination file
    const dest_path = try std.fs.path.join(allocator, &.{ dir_name, "copy.txt" });
    defer allocator.free(dest_path);

    // Create the destination file with truncate and read permissions
    var dest_file = try std.fs.cwd().createFile(dest_path, .{ .truncate = true, .read = true });
    defer dest_file.close();

    // Set up a buffered writer for the destination file
    var dest_writer_buffer: [64]u8 = undefined;
    var dest_writer_state = dest_file.writer(&dest_writer_buffer);
    const dest_writer = &dest_writer_state.interface;

    // Allocate a chunk buffer for streaming copy operations
    var chunk: [128]u8 = undefined;
    var total_bytes: usize = 0;

    // Stream data from source to destination in chunks
    // This approach is memory-efficient for large files
    while (true) {
        const read_len = try source_file.read(&chunk);
        // A read length of 0 indicates EOF
        if (read_len == 0) break;
        // Write the exact number of bytes read to the destination
        try dest_writer.writeAll(chunk[0..read_len]);
        total_bytes += read_len;
    }

    // Flush the destination writer to ensure all data is persisted
    try dest_writer.flush();

    // Retrieve file metadata to verify the copy operation
    const info = try dest_file.stat();

    // Set up a buffered stdout writer for displaying results
    var stdout_buffer: [256]u8 = undefined;
    var stdout_state = std.fs.File.stdout().writer(&stdout_buffer);
    const out = &stdout_state.interface;

    // Display copy operation statistics
    try out.print("copied {d} bytes\n", .{total_bytes});
    try out.print("destination size: {d}\n", .{info.size});

    // Rewind the destination file to read back the copied contents
    try dest_file.seekTo(0);
    const copied = try dest_file.readToEndAlloc(allocator, 16 * 1024);
    defer allocator.free(copied);

    // Display the copied file contents for verification
    try out.print("--- copy.txt ---\n{s}", .{copied});
    // Flush stdout to ensure all output is displayed
    try out.flush();
}
