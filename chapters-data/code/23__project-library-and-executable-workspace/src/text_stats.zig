const std = @import("std");

/// Text statistics and analysis structure
/// Provides functionality to analyze text content and compute various metrics
/// such as word count, line count, and character count.
pub const TextStats = struct {
    /// Total number of words found in the analyzed text
    word_count: usize,
    /// Total number of lines in the analyzed text
    line_count: usize,
    /// Total number of characters in the analyzed text
    char_count: usize,


    /// Analyze text and compute statistics
    /// Iterates through the input text to count words, lines, and characters.
    /// Words are defined as sequences of non-whitespace characters separated by whitespace.
    /// Lines are counted based on newline characters, with special handling for text
    /// that doesn't end with a newline.
    pub fn analyze(text: []const u8) TextStats {
        var stats = TextStats{
            .word_count = 0,
            .line_count = 0,
            .char_count = text.len,
        };

        // Track whether we're currently inside a word to avoid counting multiple
        // consecutive whitespace characters as separate word boundaries
        var in_word = false;
        for (text) |c| {
            if (c == '\n') {
                stats.line_count += 1;
                in_word = false;
            } else if (std.ascii.isWhitespace(c)) {
                // Whitespace marks the end of a word
                in_word = false;
            } else if (!in_word) {
                // Transition from whitespace to non-whitespace marks a new word
                stats.word_count += 1;
                in_word = true;
            }
        }

        // Count last line if text doesn't end with newline
        if (text.len > 0 and text[text.len - 1] != '\n') {
            stats.line_count += 1;
        }

        return stats;
    }

    // Format and write statistics to the provided writer
    // Outputs the statistics in a human-readable format: "Lines: X, Words: Y, Chars: Z"
    pub fn format(self: TextStats, writer: *std.Io.Writer) std.Io.Writer.Error!void {
        try writer.print("Lines: {d}, Words: {d}, Chars: {d}", .{
            self.line_count,
            self.word_count,
            self.char_count,
        });
    }
};

// Verify that TextStats correctly analyzes multi-line text with multiple words
test "TextStats analyzes simple text" {
    const text = "hello world\nfoo bar";
    const stats = TextStats.analyze(text);
    try std.testing.expectEqual(@as(usize, 2), stats.line_count);
    try std.testing.expectEqual(@as(usize, 4), stats.word_count);
    try std.testing.expectEqual(@as(usize, 19), stats.char_count);
}

// Verify that TextStats correctly handles edge case of empty input
test "TextStats handles empty text" {
    const text = "";
    const stats = TextStats.analyze(text);
    try std.testing.expectEqual(@as(usize, 0), stats.line_count);
    try std.testing.expectEqual(@as(usize, 0), stats.word_count);
    try std.testing.expectEqual(@as(usize, 0), stats.char_count);
}
