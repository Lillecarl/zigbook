const std = @import("std");

pub fn main() !void {
    std.debug.print("--- Dependency Types Comparison ---\n\n", .{});

    // Demonstrate different dependency specification patterns
    const deps = [_]Dependency{
        .{
            .name = "remote_package",
            .kind = .{ .remote = .{
                .url = "https://example.com/pkg.tar.gz",
                .hash = "122012345678...",
            } },
            .lazy = false,
        },
        .{
            .name = "local_package",
            .kind = .{ .local = .{
                .path = "../local-lib",
            } },
            .lazy = false,
        },
        .{
            .name = "lazy_optional",
            .kind = .{ .remote = .{
                .url = "https://example.com/opt.tar.gz",
                .hash = "1220abcdef...",
            } },
            .lazy = true,
        },
    };

    for (deps, 0..) |dep, i| {
        std.debug.print("Dependency {d}: {s}\n", .{ i + 1, dep.name });
        std.debug.print("  Type: {s}\n", .{@tagName(dep.kind)});
        std.debug.print("  Lazy: {}\n", .{dep.lazy});

        switch (dep.kind) {
            .remote => |r| {
                std.debug.print("  URL: {s}\n", .{r.url});
                std.debug.print("  Hash: {s}\n", .{r.hash});
                std.debug.print("  (Fetched from network, cached locally)\n", .{});
            },
            .local => |l| {
                std.debug.print("  Path: {s}\n", .{l.path});
                std.debug.print("  (No hash needed, relative to build root)\n", .{});
            },
        }
        std.debug.print("\n", .{});
    }

    std.debug.print("Key differences:\n", .{});
    std.debug.print("  - Remote: Uses hash as source of truth\n", .{});
    std.debug.print("  - Local: Direct filesystem path\n", .{});
    std.debug.print("  - Lazy: Only fetched when actually imported\n", .{});
}

const Dependency = struct {
    name: []const u8,
    kind: union(enum) {
        remote: struct {
            url: []const u8,
            hash: []const u8,
        },
        local: struct {
            path: []const u8,
        },
    },
    lazy: bool,
};
