/// Manifest describing a library that can be distributed as part of a Zig package.
pub const Manifest = struct {
    name: []const u8,
    version: []const u8,
    exports_main: bool,
    modules: []const []const u8,
};

/// Sample manifest showing how a package can expose multiple modules without providing an entry point.
pub fn sampleLibrary() Manifest {
    return .{
        .name = "widgetlib",
        .version = "0.1.0",
        .exports_main = false,
        .modules = &[_][]const u8{
            "pkg/manifest.zig",
            "pkg/render.zig",
        },
    };
}
