const std = @import("std");

// Chapter 4 §2.1 – `defer` binds cleanup to acquisition so readers see the
// full lifetime of a resource inside one lexical scope.

const JobError = error{CalibrateFailed};

const Resource = struct {
    name: []const u8,
    cleaned: bool = false,

    fn release(self: *Resource) void {
        if (!self.cleaned) {
            self.cleaned = true;
            std.debug.print("release {s}\n", .{self.name});
        }
    }
};

fn runJob(name: []const u8, should_fail: bool) JobError!void {
    std.debug.print("acquiring {s}\n", .{name});
    var res = Resource{ .name = name };
    // Place `defer` right after acquiring the resource so its release triggers
    // on every exit path, successful or otherwise.
    defer res.release();

    std.debug.print("working with {s}\n", .{name});
    if (should_fail) {
        std.debug.print("job {s} failed\n", .{name});
        return error.CalibrateFailed;
    }

    std.debug.print("job {s} succeeded\n", .{name});
}

pub fn main() !void {
    const jobs = [_]struct { name: []const u8, fail: bool }{
        .{ .name = "alpha", .fail = false },
        .{ .name = "beta", .fail = true },
    };

    for (jobs) |job| {
        std.debug.print("-- cycle {s} --\n", .{job.name});
        runJob(job.name, job.fail) catch |err| {
            // Even when a job fails, the earlier `defer` has already scheduled
            // the cleanup that keeps our resource balanced.
            std.debug.print("{s} bubbled up {s}\n", .{ job.name, @errorName(err) });
        };
    }
}
