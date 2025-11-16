// This module provides basic arithmetic operations for the zigbook build system examples.
// It demonstrates how to create a reusable module that can be imported by other Zig files.

/// Adds two 32-bit signed integers and returns their sum.
/// This function is marked pub to be accessible from other modules that import this file.
pub fn add(a: i32, b: i32) i32 {
    return a + b;
}

/// Multiplies two 32-bit signed integers and returns their product.
/// This function is marked pub to be accessible from other modules that import this file.
pub fn multiply(a: i32, b: i32) i32 {
    return a * b;
}

