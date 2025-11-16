const std = @import("std");

const Separators = " \t\r\n,.;:!?\"'()[]{}<>-/\\|`~*_";

const Entry = struct {
    word: []const u8,
    count: usize,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) @panic("memory leak");
    const allocator = gpa.allocator();

    var stdout_buffer: [256]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const out = &stdout_writer.interface;

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    const path = if (args.len >= 2) args[1] else "chapters-data/code/53__project-top-k-word-frequency-analyzer/sample_corpus.txt";
    const top_k: usize = blk: {
        if (args.len >= 3) {
            const value = std.fmt.parseInt(usize, args[2], 10) catch {
                try out.print("invalid top-k value: {s}\n", .{args[2]});
                return error.InvalidArgument;
            };
            break :blk if (value == 0) 1 else value;
        }
        break :blk 5;
    };

    var timer = try std.time.Timer.start();

    const corpus = try std.fs.cwd().readFileAlloc(allocator, path, 1024 * 1024 * 4);
    defer allocator.free(corpus);
    const read_ns = timer.lap();

    var scratch = try std.ArrayList(u8).initCapacity(allocator, 32);
    defer scratch.deinit(allocator);

    var frequencies = std.StringHashMap(usize).init(allocator);
    defer frequencies.deinit();

    var total_tokens: usize = 0;

    var it = std.mem.tokenizeAny(u8, corpus, Separators);
    while (it.next()) |raw| {
        scratch.clearRetainingCapacity();
        try scratch.appendSlice(allocator, raw);
        const slice = scratch.items;
        for (slice) |*byte| {
            byte.* = std.ascii.toLower(byte.*);
        }
        if (slice.len == 0) continue;

        const gop = try frequencies.getOrPut(slice);
        if (gop.found_existing) {
            gop.value_ptr.* += 1;
        } else {
            const owned = try allocator.dupe(u8, slice);
            gop.key_ptr.* = owned;
            gop.value_ptr.* = 1;
        }
        total_tokens += 1;
    }
    const tokenize_ns = timer.lap();

    var entries = try std.ArrayList(Entry).initCapacity(allocator, frequencies.count());
    defer {
        for (entries.items) |entry| allocator.free(entry.word);
        entries.deinit(allocator);
    }

    var map_it = frequencies.iterator();
    while (map_it.next()) |kv| {
        try entries.append(allocator, .{ .word = kv.key_ptr.*, .count = kv.value_ptr.* });
    }

    const entry_slice = entries.items;
    std.sort.heap(Entry, entry_slice, {}, struct {
        fn lessThan(_: void, a: Entry, b: Entry) bool {
            if (a.count == b.count) return std.mem.lessThan(u8, a.word, b.word);
            return a.count > b.count;
        }
    }.lessThan);
    const sort_ns = timer.lap();

    const unique_words = entries.items.len;
    const limit = if (unique_words < top_k) unique_words else top_k;

    try out.print("source -> {s}\n", .{path});
    try out.print("tokens -> {d}, unique -> {d}\n", .{ total_tokens, unique_words });
    try out.print("top {d} words:\n", .{limit});
    var index: usize = 0;
    while (index < limit) : (index += 1) {
        const entry = entry_slice[index];
        try out.print("  {d:>2}. {s} -> {d}\n", .{ index + 1, entry.word, entry.count });
    }

    try out.print("timings (ns): read={d}, tokenize={d}, sort={d}\n", .{ read_ns, tokenize_ns, sort_ns });
    try out.flush();
}
