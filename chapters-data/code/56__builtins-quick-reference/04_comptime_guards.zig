//! Demonstrates compile-time guards using @compileError and @setEvalBranchQuota.
const std = @import("std");

fn ensureVectorLength(comptime len: usize) type {
    if (len < 2) {
        @compileError("invalid vector length; expected at least 2 lanes");
    }
    return @Vector(len, u8);
}

fn boundedFib(comptime quota: u32, comptime n: u32) u64 {
    @setEvalBranchQuota(quota);
    return comptimeFib(n);
}

fn comptimeFib(comptime n: u32) u64 {
    if (n <= 1) return n;
    return comptimeFib(n - 1) + comptimeFib(n - 2);
}

test "guard accepts valid size" {
    const Vec = ensureVectorLength(4);
    const info = @typeInfo(Vec);
    try std.testing.expectEqual(@as(usize, 4), info.vector.len);
    // Uncommenting the next line triggers the compile-time guard:
    // const invalid = ensureVectorLength(1);
}

test "branch quota enables deeper recursion" {
    const result = comptime boundedFib(1024, 12);
    try std.testing.expectEqual(@as(u64, 144), result);
}
