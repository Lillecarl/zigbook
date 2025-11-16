
// This file demonstrates Zig's inline semantics and compile-time execution features.
// It shows how the `inline` keyword and `@call` builtin can control when and how
// functions are evaluated at compile-time versus runtime.

const std = @import("std");

/// Computes the nth Fibonacci number using recursion.
/// The `inline` keyword forces this function to be inlined at all call sites,
/// and the `comptime n` parameter ensures the value can be computed at compile-time.
/// This combination allows the result to be available as a compile-time constant.
inline fn fib(comptime n: usize) usize {
    return if (n <= 1) n else fib(n - 1) + fib(n - 2);
}

/// Computes the factorial of n using recursion.
/// Unlike `fib`, this function is not marked `inline`, so the compiler
/// decides whether to inline it based on optimization heuristics.
/// It can be called at either compile-time or runtime.
fn factorial(n: usize) usize {
    return if (n <= 1) 1 else n * factorial(n - 1);
}

// Demonstrates that an inline function with comptime parameters
// propagates compile-time execution to its call sites.
// The entire computation happens at compile-time within the comptime block.
test "inline fibonacci propagates comptime" {
    comptime {
        const value = fib(10);
        try std.testing.expectEqual(@as(usize, 55), value);
    }
}

// Demonstrates the `@call` builtin with `.compile_time` modifier.
// This forces the function call to be evaluated at compile-time,
// even though `factorial` is not marked `inline` and takes non-comptime parameters.
test "@call compile_time modifier" {
    const result = @call(.compile_time, factorial, .{5});
    try std.testing.expectEqual(@as(usize, 120), result);
}

// Verifies that a non-inline function can still be called at runtime.
// The input is a runtime value, so the computation happens during execution.
test "runtime factorial still works" {
    const input: usize = 6;
    const value = factorial(input);
    try std.testing.expectEqual(@as(usize, 720), value);
}
