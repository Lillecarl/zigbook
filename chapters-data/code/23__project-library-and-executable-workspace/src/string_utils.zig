
// Import the standard library for testing utilities
const std = @import("std");

/// String utilities for text processing
pub const StringUtils = struct {
    /// Count occurrences of a character in a string
    /// Returns the total number of times the specified character appears
    pub fn countChar(text: []const u8, char: u8) usize {
        var count: usize = 0;
        // Iterate through each character in the text
        for (text) |c| {
            // Increment counter when matching character is found
            if (c == char) count += 1;
        }
        return count;
    }

    /// Check if string contains only ASCII characters
    /// ASCII characters have values from 0-127
    pub fn isAscii(text: []const u8) bool {
        for (text) |c| {
            // Any character with value > 127 is non-ASCII
            if (c > 127) return false;
        }
        return true;
    }

    /// Reverse a string in place
    /// Modifies the input buffer directly using two-pointer technique
    pub fn reverse(text: []u8) void {
        // Early return for empty strings
        if (text.len == 0) return;
        
        var left: usize = 0;
        var right: usize = text.len - 1;
        
        // Swap characters from both ends moving towards the center
        while (left < right) {
            const temp = text[left];
            text[left] = text[right];
            text[right] = temp;
            left += 1;
            right -= 1;
        }
    }
};

// Test suite verifying countChar functionality with various inputs
test "countChar counts occurrences" {
    const text = "hello world";
    // Verify counting of 'l' character (appears 3 times)
    try std.testing.expectEqual(@as(usize, 3), StringUtils.countChar(text, 'l'));
    // Verify counting of 'o' character (appears 2 times)
    try std.testing.expectEqual(@as(usize, 2), StringUtils.countChar(text, 'o'));
    // Verify counting returns 0 for non-existent character
    try std.testing.expectEqual(@as(usize, 0), StringUtils.countChar(text, 'x'));
}

// Test suite verifying ASCII detection for different character sets
test "isAscii detects ASCII strings" {
    // Standard ASCII letters should return true
    try std.testing.expect(StringUtils.isAscii("hello"));
    // ASCII digits should return true
    try std.testing.expect(StringUtils.isAscii("123"));
    // String with non-ASCII character (é = 233) should return false
    try std.testing.expect(!StringUtils.isAscii("héllo"));
}

// Test suite verifying in-place string reversal
test "reverse reverses string" {
    // Create a mutable buffer to test in-place reversal
    var buffer = [_]u8{ 'h', 'e', 'l', 'l', 'o' };
    StringUtils.reverse(&buffer);
    // Verify the buffer contents are reversed
    try std.testing.expectEqualSlices(u8, "olleh", &buffer);
}
