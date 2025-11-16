const std = @import("std");

// Chapter 4 §2.2 – staged setup guarded with `errdefer` so partially
// initialized channels roll back automatically on failure.

const SetupError = error{ OpenFailed, RegisterFailed };

const Channel = struct {
    name: []const u8,
    opened: bool = false,
    registered: bool = false,

    fn teardown(self: *Channel) void {
        if (self.registered) {
            std.debug.print("deregister \"{s}\"\n", .{self.name});
            self.registered = false;
        }
        if (self.opened) {
            std.debug.print("closing \"{s}\"\n", .{self.name});
            self.opened = false;
        }
    }
};

fn setupChannel(name: []const u8, fail_on_register: bool) SetupError!Channel {
    std.debug.print("opening \"{s}\"\n", .{name});

    if (name.len == 0) {
        return error.OpenFailed;
    }

    var channel = Channel{ .name = name, .opened = true };
    errdefer {
        // If any later step fails we run the rollback block, mirroring the
        // “errdefer Rolls Back Partial Initialization” section.
        std.debug.print("rollback \"{s}\"\n", .{name});
        channel.teardown();
    }

    std.debug.print("registering \"{s}\"\n", .{name});
    if (fail_on_register) {
        return error.RegisterFailed;
    }

    channel.registered = true;
    return channel;
}

pub fn main() !void {
    std.debug.print("-- success path --\n", .{});
    var primary = try setupChannel("primary", false);
    defer primary.teardown();

    std.debug.print("-- register failure --\n", .{});
    _ = setupChannel("backup", true) catch |err| {
        std.debug.print("setup failed with {s}\n", .{@errorName(err)});
    };

    std.debug.print("-- open failure --\n", .{});
    _ = setupChannel("", false) catch |err| {
        std.debug.print("setup failed with {s}\n", .{@errorName(err)});
    };
}
