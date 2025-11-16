const std = @import("std");

pub fn main() !void {
    var stdout_buffer: [256]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const out = &stdout_writer.interface;
    const on_valgrind = std.valgrind.runningOnValgrind() != 0;
    try out.print("running_on_valgrind -> {s}\n", .{if (on_valgrind) "yes" else "no"});

    var arena_storage: [96]u8 = undefined;
    var arena = std.heap.FixedBufferAllocator.init(&arena_storage);
    const allocator = arena.allocator();

    var span = try allocator.alloc(u8, 48);
    defer {
        std.valgrind.freeLikeBlock(span.ptr, 0);
        allocator.free(span);
    }

    // Announce a custom allocation to Valgrind so leak reports point at our call site.
    std.valgrind.mallocLikeBlock(span, 0, true);

    const label: [:0]const u8 = "workspace-span\x00";
    const block_id = std.valgrind.memcheck.createBlock(span, label);
    defer _ = std.valgrind.memcheck.discard(block_id);

    std.valgrind.memcheck.makeMemDefined(span);
    std.valgrind.memcheck.makeMemNoAccess(span[32..]);
    std.valgrind.memcheck.makeMemDefinedIfAddressable(span[32..]);

    const leak_bytes = std.valgrind.memcheck.countLeaks();
    try out.print("leaks_bytes -> {d}\n", .{leak_bytes.leaked});

    std.valgrind.memcheck.doQuickLeakCheck();

    const error_total = std.valgrind.countErrors();
    try out.print("errors_seen -> {d}\n", .{error_total});
    try out.flush();
}
