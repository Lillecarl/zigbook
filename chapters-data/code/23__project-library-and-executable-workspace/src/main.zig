const std = @import("std");
const textkit = @import("textkit");

pub fn main() !void {
    // Set up a general-purpose allocator for dynamic memory allocation
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Retrieve command line arguments passed to the program
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    // Ensure at least one command argument is provided (args[0] is the program name)
    if (args.len < 2) {
        try printUsage();
        return;
    }

    // Extract the command verb from the first argument
    const command = args[1];

    // Dispatch to the appropriate handler based on the command
    if (std.mem.eql(u8, command, "analyze")) {
        // 'analyze' requires a filename argument
        if (args.len < 3) {
            std.debug.print("Error: analyze requires a filename\n", .{});
            return;
        }
        try analyzeFile(allocator, args[2]);
    } else if (std.mem.eql(u8, command, "reverse")) {
        // 'reverse' requires text to reverse
        if (args.len < 3) {
            std.debug.print("Error: reverse requires text\n", .{});
            return;
        }
        try reverseText(args[2]);
    } else if (std.mem.eql(u8, command, "count")) {
        // 'count' requires both text and a single character to count
        if (args.len < 4) {
            std.debug.print("Error: count requires text and character\n", .{});
            return;
        }
        // Validate that the character argument is exactly one byte
        if (args[3].len != 1) {
            std.debug.print("Error: character must be single byte\n", .{});
            return;
        }
        try countCharacter(args[2], args[3][0]);
    } else {
        // Handle unrecognized commands
        std.debug.print("Unknown command: {s}\n", .{command});
        try printUsage();
    }
}

/// Print usage information to guide users on available commands
fn printUsage() !void {
    const usage =
        \\TextKit CLI - Text processing utility
        \\
        \\Usage:
        \\  textkit-cli analyze <file>      Analyze text file statistics
        \\  textkit-cli reverse <text>      Reverse the given text
        \\  textkit-cli count <text> <char> Count character occurrences
        \\
    ;
    std.debug.print("{s}", .{usage});
}

/// Read a file and display statistical analysis of its text content
fn analyzeFile(allocator: std.mem.Allocator, filename: []const u8) !void {
    // Open the file in read-only mode from the current working directory
    const file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    // Read the entire file content into memory (limited to 1MB)
    const content = try file.readToEndAlloc(allocator, 1024 * 1024);
    defer allocator.free(content);

    // Use textkit library to compute text statistics
    const stats = textkit.TextStats.analyze(content);

    // Display the computed statistics to the user
    std.debug.print("File: {s}\n", .{filename});
    std.debug.print("  Lines: {d}\n", .{stats.line_count});
    std.debug.print("  Words: {d}\n", .{stats.word_count});
    std.debug.print("  Characters: {d}\n", .{stats.char_count});
    std.debug.print("  ASCII only: {}\n", .{textkit.StringUtils.isAscii(content)});
}

/// Reverse the provided text and display both original and reversed versions
fn reverseText(text: []const u8) !void {
    // Allocate a stack buffer for in-place reversal
    var buffer: [1024]u8 = undefined;
    
    // Ensure the input text fits within the buffer
    if (text.len > buffer.len) {
        std.debug.print("Error: text too long (max {d} chars)\n", .{buffer.len});
        return;
    }

    // Copy input text into the mutable buffer for reversal
    @memcpy(buffer[0..text.len], text);
    
    // Perform in-place reversal using textkit utility
    textkit.StringUtils.reverse(buffer[0..text.len]);

    // Display both the original and reversed text
    std.debug.print("Original: {s}\n", .{text});
    std.debug.print("Reversed: {s}\n", .{buffer[0..text.len]});
}

/// Count occurrences of a specific character in the provided text
fn countCharacter(text: []const u8, char: u8) !void {
    // Use textkit to count character occurrences
    const count = textkit.StringUtils.countChar(text, char);
    
    // Display the count result
    std.debug.print("Character '{c}' appears {d} time(s) in: {s}\n", .{
        char,
        count,
        text,
    });
}

// Test that all declarations in this module are reachable and compile correctly
test "main program compiles" {
    std.testing.refAllDecls(@This());
}
