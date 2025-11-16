// Conceptual example showing the dependency resolution pipeline
const std = @import("std");

const DependencyState = enum {
    declared, // Listed in build.zig.zon
    downloading, // URL being fetched
    verifying, // Hash being checked
    cached, // Stored in global cache
    available, // Ready for use
};

const Dependency = struct {
    name: []const u8,
    url: ?[]const u8,
    path: ?[]const u8,
    hash: ?[]const u8,
    lazy: bool,
    state: DependencyState,
};

pub fn main() !void {
    std.debug.print("--- Zig Package Manager Resolution Pipeline ---\n\n", .{});

    // Stage 1: Parse build.zig.zon
    std.debug.print("1. Parse build.zig.zon dependencies\n", .{});
    var deps = [_]Dependency{
        .{
            .name = "core",
            .path = "../core",
            .url = null,
            .hash = null,
            .lazy = false,
            .state = .declared,
        },
        .{
            .name = "utils",
            .url = "https://example.com/utils.tar.gz",
            .path = null,
            .hash = "1220abcd...",
            .lazy = false,
            .state = .declared,
        },
        .{
            .name = "optional_viz",
            .url = "https://example.com/viz.tar.gz",
            .path = null,
            .hash = "1220ef01...",
            .lazy = true,
            .state = .declared,
        },
    };

    // Stage 2: Resolve eager dependencies
    std.debug.print("\n2. Resolve eager dependencies\n", .{});
    for (&deps) |*dep| {
        if (!dep.lazy) {
            std.debug.print("   - {s}: ", .{dep.name});
            if (dep.path) |p| {
                std.debug.print("local path '{s}' → available\n", .{p});
                dep.state = .available;
            } else if (dep.url) |_| {
                std.debug.print("fetching → verifying → cached → available\n", .{});
                dep.state = .available;
            }
        }
    }

    // Stage 3: Lazy dependencies deferred
    std.debug.print("\n3. Lazy dependencies (deferred until used)\n", .{});
    for (deps) |dep| {
        if (dep.lazy) {
            std.debug.print("   - {s}: waiting for lazyDependency() call\n", .{dep.name});
        }
    }

    // Stage 4: Build script execution triggers lazy fetch
    std.debug.print("\n4. Build script requests lazy dependency\n", .{});
    std.debug.print("   - optional_viz requested → fetching now\n", .{});

    // Stage 5: Cache lookup
    std.debug.print("\n5. Cache locations\n", .{});
    std.debug.print("   - Global: ~/.cache/zig/p/<hash>/\n", .{});
    std.debug.print("   - Project: .zig-cache/\n", .{});

    std.debug.print("\n=== Resolution Complete ===\n", .{});
}
