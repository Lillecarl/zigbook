const std = @import("std");

pub fn main() !void {
    // Demonstrate parsing and introspecting build.zig.zon fields
    // In practice, the build runner handles this automatically
    const zon_example =
        \\.{
        \\    .name = .demo,
        \\    .version = "0.1.0",
        \\    .minimum_zig_version = "0.15.2",
        \\    .fingerprint = 0x1234567890abcdef,
        \\    .paths = .{"build.zig", "src"},
        \\    .dependencies = .{},
        \\}
    ;

    std.debug.print("--- build.zig.zon Field Demo ---\n", .{});
    std.debug.print("Sample ZON structure:\n{s}\n\n", .{zon_example});

    std.debug.print("Field explanations:\n", .{});
    std.debug.print("  .name: Package identifier (symbol literal)\n", .{});
    std.debug.print("  .version: Semantic version string\n", .{});
    std.debug.print("  .minimum_zig_version: Minimum supported Zig\n", .{});
    std.debug.print("  .fingerprint: Unique package ID (hex integer)\n", .{});
    std.debug.print("  .paths: Files included in package distribution\n", .{});
    std.debug.print("  .dependencies: External packages required\n", .{});

    std.debug.print("\nNote: Zig 0.15.2 uses .fingerprint for unique identity\n", .{});
    std.debug.print("      (Previously used UUID-style identifiers)\n", .{});
}
