//! Highlights a layered module layout with focused helper functions and tests.
const std = @import("std");

/// Errors that can emerge while normalizing user-provided retry policies.
pub const RetryPolicyError = error{
    ZeroAttempts,
    ExcessiveDelay,
};

/// Encapsulates retry behaviour for a network client, including sensible defaults.
pub const RetryPolicy = struct {
    max_attempts: u8 = 3,
    delay_ms: u32 = 100,

    /// Indicates whether exponential backoff is active.
    pub fn isBackoffEnabled(self: RetryPolicy) bool {
        return self.delay_ms > 0 and self.max_attempts > 1;
    }
};

/// Partial options provided by configuration files or CLI flags.
pub const PartialRetryOptions = struct {
    max_attempts: ?u8 = null,
    delay_ms: ?u32 = null,
};

/// Builds a retry policy from optional overrides while keeping default reasoning centralized.
pub fn makeRetryPolicy(options: PartialRetryOptions) RetryPolicy {
    return RetryPolicy{
        .max_attempts = options.max_attempts orelse 3,
        .delay_ms = options.delay_ms orelse 100,
    };
}

fn validate(policy: RetryPolicy) RetryPolicyError!RetryPolicy {
    if (policy.max_attempts == 0) return RetryPolicyError.ZeroAttempts;
    if (policy.delay_ms > 60_000) return RetryPolicyError.ExcessiveDelay;
    return policy;
}

/// Produces a validated policy, emphasising the flow from raw input to constrained output.
pub fn finalizeRetryPolicy(options: PartialRetryOptions) RetryPolicyError!RetryPolicy {
    const policy = makeRetryPolicy(options);
    return validate(policy);
}

test "finalize rejects zero attempts" {
    try std.testing.expectError(
        RetryPolicyError.ZeroAttempts,
        finalizeRetryPolicy(.{ .max_attempts = 0 }),
    );
}

test "finalize accepts defaults" {
    const policy = try finalizeRetryPolicy(.{});
    try std.testing.expectEqual(@as(u8, 3), policy.max_attempts);
    try std.testing.expect(policy.isBackoffEnabled());
}
