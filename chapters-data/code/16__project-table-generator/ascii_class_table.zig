const std = @import("std");

/// Helper function to obtain a buffered standard output writer.
/// Uses a static buffer to avoid repeated allocations.
fn stdout() *std.Io.Writer {
    const g = struct {
        var buf: [4096]u8 = undefined;
        var w = std.fs.File.stdout().writer(&buf);
    };
    return &g.w.interface;
}

/// Bit flags representing ASCII character classes.
/// Multiple flags can be combined using bitwise OR.
const Class = struct {
    pub const digit: u8 = 0x01;  // 0-9
    pub const alpha: u8 = 0x02;  // A-Z, a-z
    pub const space: u8 = 0x04;  // space, newline, tab, carriage return
    pub const punct: u8 = 0x08;  // punctuation characters
};

/// Builds a lookup table mapping each byte (0-255) to its character class flags.
/// This function runs at compile time, producing a constant table embedded in the binary.
fn buildAsciiClassTable() [256]u8 {
    // Initialize all entries to 0 (no class flags set)
    var t: [256]u8 = .{0} ** 256;
    
    // Iterate over all possible byte values at compile time
    comptime var b: usize = 0;
    inline while (b < 256) : (b += 1) {
        const ch: u8 = @intCast(b);
        var m: u8 = 0;  // Accumulator for class flags
        
        // Check if character is a digit (0-9)
        if (ch >= '0' and ch <= '9') m |= Class.digit;
        
        // Check if character is alphabetic (A-Z or a-z)
        if ((ch >= 'A' and ch <= 'Z') or (ch >= 'a' and ch <= 'z')) m |= Class.alpha;
        
        // Check if character is whitespace (space, newline, tab, carriage return)
        if (ch == ' ' or ch == '\n' or ch == '\t' or ch == '\r') m |= Class.space;
        
        // Check if character is punctuation (printable, non-alphanumeric, non-whitespace)
        if (std.ascii.isPrint(ch) and !std.ascii.isAlphanumeric(ch) and !std.ascii.isWhitespace(ch)) m |= Class.punct;
        
        // Store the computed flags for this byte value
        t[b] = m;
    }
    return t;
}

/// Counts occurrences of each character class in the input string.
/// Uses the precomputed lookup table for O(1) classification per character.
fn countKinds(s: []const u8) struct { digits: usize, letters: usize, spaces: usize, punct: usize } {
    // Build the classification table (happens at compile time)
    const T = buildAsciiClassTable();
    
    // Initialize counters for each character class
    var c = struct { digits: usize = 0, letters: usize = 0, spaces: usize = 0, punct: usize = 0 }{};
    
    // Iterate through each byte in the input string
    var i: usize = 0;
    while (i < s.len) : (i += 1) {
        // Look up the class flags for the current byte
        const m = T[s[i]];
        
        // Test each flag and increment the corresponding counter
        if ((m & Class.digit) != 0) c.digits += 1;
        if ((m & Class.alpha) != 0) c.letters += 1;
        if ((m & Class.space) != 0) c.spaces += 1;
        if ((m & Class.punct) != 0) c.punct += 1;
    }
    
    // Return the counts as an anonymous struct
    return .{ .digits = c.digits, .letters = c.letters, .spaces = c.spaces, .punct = c.punct };
}

pub fn main() !void {
    // Get buffered output writer
    const out = stdout();
    
    // Define test string containing various character classes
    const s = "Hello, Zig 0.15.2!  \t\n";
    
    // Count each character class in the test string
    const c = countKinds(s);
    
    // Print the input string
    try out.print("input: {s}\n", .{s});
    
    // Print the computed counts for each character class
    try out.print("digits={} letters={} spaces={} punct={}\n", .{ c.digits, c.letters, c.spaces, c.punct });
    
    // Ensure buffered output is written to stdout
    try out.flush();
}
