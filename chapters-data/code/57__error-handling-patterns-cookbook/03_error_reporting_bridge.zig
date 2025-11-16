//! Bridges domain errors to user-facing log messages.
const std = @import("std");

pub const ApiError = error{
    NotFound,
    RateLimited,
    Backend,
};

fn describeApiError(err: ApiError, writer: anytype) !void {
    switch (err) {
        ApiError.NotFound => try writer.writeAll("resource not found; check identifier"),
        ApiError.RateLimited => try writer.writeAll("rate limit exceeded; retry later"),
        ApiError.Backend => try writer.writeAll("upstream dependency failed; escalate"),
    }
}

const Action = struct {
    outcomes: []const ?ApiError,
    index: usize = 0,

    fn invoke(self: *Action) ApiError!void {
        if (self.index >= self.outcomes.len) return;
        const outcome = self.outcomes[self.index];
        self.index += 1;
        if (outcome) |err| {
            return err;
        }
    }
};

pub fn runAndReport(action: *Action, writer: anytype) !void {
    action.invoke() catch |err| {
        try writer.writeAll("Request failed: ");
        try describeApiError(err, writer);
        return;
    };
    try writer.writeAll("Request succeeded");
}

test "runAndReport surfaces friendly error message" {
    var action = Action{ .outcomes = &[_]?ApiError{ApiError.NotFound} };
    var buffer: [128]u8 = undefined;
    var stream = std.io.fixedBufferStream(&buffer);

    try runAndReport(&action, stream.writer());
    const message = stream.getWritten();
    try std.testing.expectEqualStrings("Request failed: resource not found; check identifier", message);
}

test "runAndReport acknowledges success" {
    var action = Action{ .outcomes = &[_]?ApiError{null} };
    var buffer: [64]u8 = undefined;
    var stream = std.io.fixedBufferStream(&buffer);

    try runAndReport(&action, stream.writer());
    const message = stream.getWritten();
    try std.testing.expectEqualStrings("Request succeeded", message);
}
