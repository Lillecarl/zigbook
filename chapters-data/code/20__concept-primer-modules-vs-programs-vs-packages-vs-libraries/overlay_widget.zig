const std = @import("std");

/// Summary of a package registration as seen from the consumer invoking `--pkg-begin`.
pub const PackageDetails = struct {
    package_name: []const u8,
    role: []const u8,
    optimize_mode: []const u8,
    target_os: []const u8,
};

/// Render a formatted summary that demonstrates how package registration exposes modules by name.
pub fn renderSummary(writer: anytype, details: PackageDetails) !void {
    try writer.print("registered package: {s}\n", .{details.package_name});
    try writer.print("role advertised: {s}\n", .{details.role});
    try writer.print("optimize mode: {s}\n", .{details.optimize_mode});
    try writer.print("target os: {s}\n", .{details.target_os});
    try writer.print(
        "resolved module namespace: overlay → pub decls: {d}\n",
        .{moduleDeclCount()},
    );
}

fn moduleDeclCount() usize {
    // Enumerate the declarations exported by this module to simulate API surface reporting.
    return std.meta.declarations(@This()).len;
}
