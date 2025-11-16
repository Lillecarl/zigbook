//! Demonstrates union construction that forwards nested result locations.
const std = @import("std");

pub const Resource = struct {
    name: []const u8,
    payload: [32]u8,
};

pub const LookupResult = union(enum) {
    hit: Resource,
    miss: void,
    malformed: []const u8,
};

const CatalogEntry = struct {
    name: []const u8,
    data: []const u8,
};

pub fn lookup(name: []const u8, catalog: []const CatalogEntry) LookupResult {
    for (catalog) |entry| {
        if (std.mem.eql(u8, entry.name, name)) {
            var buffer: [32]u8 = undefined;
            const len = @min(buffer.len, entry.data.len);
            std.mem.copyForwards(u8, buffer[0..len], entry.data[0..len]);
            return .{ .hit = .{ .name = entry.name, .payload = buffer } };
        }
    }

    if (name.len == 0) return .{ .malformed = "empty identifier" };
    return .miss;
}

test "lookup returns hit variant with payload" {
    const items = [_]CatalogEntry{
        .{ .name = "alpha", .data = "hello" },
        .{ .name = "beta", .data = "world" },
    };

    const result = lookup("beta", &items);
    switch (result) {
        .hit => |res| {
            try std.testing.expectEqualStrings("beta", res.name);
            try std.testing.expectEqualStrings("world", res.payload[0..5]);
        },
        else => try std.testing.expect(false),
    }
}

test "lookup surfaces malformed input" {
    const items = [_]CatalogEntry{.{ .name = "alpha", .data = "hello" }};
    const result = lookup("", &items);
    switch (result) {
        .malformed => |msg| try std.testing.expectEqualStrings("empty identifier", msg),
        else => try std.testing.expect(false),
    }
}
