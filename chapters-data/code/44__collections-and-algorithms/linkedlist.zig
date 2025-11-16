const std = @import("std");

const Node = struct {
    data: i32,
    link: std.DoublyLinkedList.Node = .{},
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var list = std.DoublyLinkedList{};

    var node1 = try allocator.create(Node);
    node1.* = .{ .data = 10 };
    list.append(&node1.link);

    var node2 = try allocator.create(Node);
    node2.* = .{ .data = 20 };
    list.append(&node2.link);

    var node3 = try allocator.create(Node);
    node3.* = .{ .data = 30 };
    list.append(&node3.link);

    var it = list.first;
    while (it) |node| : (it = node.next) {
        const data_node: *Node = @fieldParentPtr("link", node);
        std.debug.print("Node: {d}\n", .{data_node.data});
    }

    // Clean up
    allocator.destroy(node1);
    allocator.destroy(node2);
    allocator.destroy(node3);
}
