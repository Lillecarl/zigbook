//! TextKit - A text processing library
//!
//! This library provides utilities for text manipulation and analysis,
//! including string utilities and text statistics.

pub const StringUtils = @import("string_utils.zig").StringUtils;
pub const TextStats = @import("text_stats.zig").TextStats;

const std = @import("std");

/// Library version information
pub const version = std.SemanticVersion{
    .major = 1,
    .minor = 0,
    .patch = 0,
};

test {
    // Ensure all module tests are run
    std.testing.refAllDecls(@This());
}
