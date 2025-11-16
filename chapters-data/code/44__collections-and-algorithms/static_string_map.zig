const std = @import("std");

const status_codes = std.StaticStringMap(u32).initComptime(.{
    .{ "ok", 200 },
    .{ "created", 201 },
    .{ "not_found", 404 },
    .{ "server_error", 500 },
});

pub fn main() !void {
    std.debug.print("Status code for 'ok': {d}\n", .{status_codes.get("ok").?});
    std.debug.print("Status code for 'not_found': {d}\n", .{status_codes.get("not_found").?});
    std.debug.print("Status code for 'server_error': {d}\n", .{status_codes.get("server_error").?});
}
