const root = @import("root");
const manifest_pkg = @import("pkg/manifest.zig");

/// Snapshot describing the classification of a module or library surface.
pub const ModuleSnapshot = struct {
    name: []const u8,
    version: []const u8,
    exports_main: bool,
    role: []const u8,
    public_symbol_count: usize,
};

/// Mapping between a development goal and the recommended Zig unit to reach for.
pub const IntentDecision = struct {
    goal: []const u8,
    recommendation: []const u8,
};

/// Introspects the root module to decide whether it behaves like a program or pure module.
pub fn rootSnapshot() ModuleSnapshot {
    const exports_main = @hasDecl(root, "main");
    return .{
        .name = "root",
        .version = "n/a",
        .exports_main = exports_main,
        .role = if (exports_main) "program" else "module",
        .public_symbol_count = root.PublicSurface.len,
    };
}

/// Uses the manifest provided by the root module to describe the library surface registered for reuse.
pub fn librarySnapshot() ModuleSnapshot {
    const manifest = root.libraryManifest();
    return .{
        .name = manifest.name,
        .version = manifest.version,
        .exports_main = manifest.exports_main,
        .role = if (manifest.exports_main) "program" else "library",
        .public_symbol_count = manifest.modules.len,
    };
}

/// Curated intent-to-unit recommendations that support the cheat sheet printed by the demo.
pub fn decisions() []const IntentDecision {
    return &[_]IntentDecision{
        .{ .goal = "ship a CLI entry point", .recommendation = "program" },
        .{ .goal = "publish reusable code", .recommendation = "package + library" },
        .{ .goal = "share type definitions inside a workspace", .recommendation = "module" },
    };
}
