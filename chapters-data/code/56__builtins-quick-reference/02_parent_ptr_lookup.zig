//! Demonstrates `@fieldParentPtr` to recover container pointers safely.
const std = @import("std");

const Node = struct {
    id: u32,
    payload: Payload,
};

const Payload = struct {
    node_ptr: *const Node,
    value: []const u8,
};

fn makeNode(id: u32, value: []const u8) Node {
    var node = Node{
        .id = id,
        .payload = undefined,
    };
    node.payload = Payload{
        .node_ptr = &node,
        .value = value,
    };
    return node;
}

test "parent pointer recovers owning node" {
    var node = makeNode(7, "ready");
    const parent: *const Node = @fieldParentPtr("payload", &node.payload);
    try std.testing.expectEqual(@as(u32, 7), parent.id);
}

test "field access respects const rules" {
    var node = makeNode(3, "go");
    const parent: *const Node = @fieldParentPtr("payload", &node.payload);
    try std.testing.expectEqualStrings("go", parent.payload.value);
}
