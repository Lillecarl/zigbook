const std = @import("std");
const builtin = @import("builtin");

/// Map type alias: word → frequency count
const Map = std.StringHashMap(u64);

/// Normalize a raw token by converting ASCII letters to lowercase and
/// stripping non-alphanumeric characters from both ends.
/// Returns a slice into the provided buffer; caller owns the buffer.
fn normalizeWord(allocator: std.mem.Allocator, raw: []const u8) ![]const u8 {
    // Allocate a buffer large enough to hold the entire input
    var buf = try allocator.alloc(u8, raw.len);
    var n: usize = 0;
    
    // Convert uppercase ASCII to lowercase (A-Z → a-z)
    for (raw) |c| {
        var ch = c;
        if (ch >= 'A' and ch <= 'Z') ch = ch + 32;
        buf[n] = ch;
        n += 1;
    }
    
    // Strip leading non-alphanumeric characters
    var start: usize = 0;
    while (start < n and (buf[start] < '0' or (buf[start] > '9' and buf[start] < 'a') or buf[start] > 'z')) : (start += 1) {}
    
    // Strip trailing non-alphanumeric characters
    var end: usize = n;
    while (end > start and (buf[end - 1] < '0' or (buf[end - 1] > '9' and buf[end - 1] < 'a') or buf[end - 1] > 'z')) : (end -= 1) {}
    
    // If nothing remains after stripping, return empty slice
    if (end <= start) return buf[0..0];
    return buf[start..end];
}

/// Tokenize text on whitespace and populate the provided map with
/// normalized word frequencies. Keys are normalized copies allocated
/// from the provided allocator.
fn tokenizeAndCount(allocator: std.mem.Allocator, text: []const u8, map: *Map) !void {
    // Split on any whitespace character
    var it = std.mem.tokenizeAny(u8, text, " \t\r\n");
    while (it.next()) |raw| {
        const word = try normalizeWord(allocator, raw);
        if (word.len == 0) continue; // skip empty tokens
        
        // Insert or update the word count
        const gop = try map.getOrPut(word);
        if (!gop.found_existing) {
            gop.value_ptr.* = 1;
        } else {
            gop.value_ptr.* += 1;
        }
    }
}

/// Arguments passed to each worker thread
const WorkerArgs = struct {
    slice: []const u8,               // segment of text to process
    counts: *Map,                    // thread-local frequency map
    arena: *std.heap.ArenaAllocator, // arena for temporary allocations
};

/// Worker function executed by each thread; tokenizes and counts words
/// in its assigned text segment without shared state.
fn countWorker(args: WorkerArgs) void {
    // Each worker writes only to its own map instance; merge happens later
    tokenizeAndCount(args.arena.allocator(), args.slice, args.counts) catch |err| {
        std.debug.print("worker error: {s}\n", .{@errorName(err)});
    };
}

/// Read an entire file into a newly allocated buffer, capped at 64 MiB.
fn readAllAlloc(path: []const u8, allocator: std.mem.Allocator) ![]u8 {
    var file = try std.fs.cwd().openFile(path, .{});
    defer file.close();
    return try file.readToEndAlloc(allocator, 64 * 1024 * 1024);
}

/// Partition text into roughly equal segments, ensuring shard boundaries
/// fall at whitespace to avoid splitting words. Returns owned slice of slices.
fn shard(text: []const u8, shards: usize, allocator: std.mem.Allocator) ![]const []const u8 {
    // If only one shard requested or text is empty, return single segment
    if (shards <= 1 or text.len == 0) {
        var single = try allocator.alloc([]const u8, 1);
        single[0] = text;
        return single;
    }
    
    const approx = text.len / shards; // approximate bytes per shard
    var parts = std.array_list.Managed([]const u8).init(allocator);
    defer parts.deinit();
    
    var i: usize = 0;
    while (i < text.len) {
        var end = @min(text.len, i + approx);
        
        // Push shard boundary forward to the next whitespace character
        while (end < text.len and text[end] != ' ' and text[end] != '\n' and text[end] != '\t' and text[end] != '\r') : (end += 1) {}
        
        // If no whitespace found, fall back to approximate boundary
        if (end == i) end = @min(text.len, i + approx);
        
        try parts.append(text[i..end]);
        i = end;
    }
    return try parts.toOwnedSlice();
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Set up buffered stdout for efficient printing
    var stdout_buf: [1024]u8 = undefined;
    var stdout_state = std.fs.File.stdout().writer(&stdout_buf);
    const out = &stdout_state.interface;

    // Parse command-line arguments
    var args_it = try std.process.argsWithAllocator(allocator);
    defer args_it.deinit();

    _ = args_it.next(); // skip program name
    const path = args_it.next() orelse {
        try out.print("usage: parallel-wc <file>\n", .{});
        try out.flush();
        return;
    };

    // Read entire file into memory
    const text = try readAllAlloc(path, allocator);
    defer allocator.free(text);

    // Determine shard count: use CPU count unless single-threaded build
    const cpu = std.Thread.getCpuCount() catch 1;
    const shard_count = if (builtin.single_threaded) 1 else if (cpu < 1) 1 else cpu;

    // Partition text into shards at whitespace boundaries
    const parts = try shard(text, shard_count, allocator);
    defer allocator.free(parts);

    // Allocate per-shard arenas and maps
    var arenas = try allocator.alloc(std.heap.ArenaAllocator, parts.len);
    defer allocator.free(arenas);

    var maps = try allocator.alloc(Map, parts.len);
    defer allocator.free(maps);

    // Allocate thread handles if multi-threaded
    var threads = if (builtin.single_threaded) &[_]std.Thread{} else try allocator.alloc(std.Thread, parts.len);
    defer if (!builtin.single_threaded) allocator.free(threads);

    // Spawn worker threads (or execute inline if single-threaded)
    for (parts, 0..) |seg, i| {
        arenas[i] = std.heap.ArenaAllocator.init(allocator);
        maps[i] = Map.init(allocator);
        try maps[i].ensureTotalCapacity(1024); // pre-size to reduce rehashing
        
        if (builtin.single_threaded) {
            // Execute worker inline
            countWorker(.{ .slice = seg, .counts = &maps[i], .arena = &arenas[i] });
        } else {
            // Spawn a thread for this shard
            threads[i] = try std.Thread.spawn(.{}, countWorker, .{WorkerArgs{ .slice = seg, .counts = &maps[i], .arena = &arenas[i] }});
        }
    }

    // Wait for all threads to complete
    if (!builtin.single_threaded) {
        for (threads) |t| t.join();
    }

    // Merge per-thread maps into a single global map
    var total = Map.init(allocator);
    defer total.deinit();
    try total.ensureTotalCapacity(4096); // pre-size for merged data
    
    for (maps, 0..) |*m, i| {
        var it = m.iterator();
        while (it.next()) |e| {
            const key_bytes = e.key_ptr.*;
            
            // Duplicate key into total's allocator to take ownership,
            // since arenas will be freed shortly
            const dup = try allocator.dupe(u8, key_bytes);
            const gop = try total.getOrPut(dup);
            
            if (!gop.found_existing) {
                gop.value_ptr.* = e.value_ptr.*;
            } else {
                // Key already exists; free the duplicate and accumulate count
                allocator.free(dup);
                gop.value_ptr.* += e.value_ptr.*;
            }
        }
        
        // Free per-thread arena and map
        arenas[i].deinit();
        m.deinit();
    }

    // Build a sortable list of (word, count) entries
    const Entry = struct { k: []const u8, v: u64 };
    var entries = std.array_list.Managed(Entry).init(allocator);
    defer entries.deinit();

    var it = total.iterator();
    while (it.next()) |e| {
        try entries.append(.{ .k = e.key_ptr.*, .v = e.value_ptr.* });
    }

    // Sort by count descending, then alphabetically
    std.sort.pdq(Entry, entries.items, {}, struct {
        fn lessThan(_: void, a: Entry, b: Entry) bool {
            if (a.v == b.v) return std.mem.lessThan(u8, a.k, b.k);
            return a.v > b.v; // descending by count
        }
    }.lessThan);

    // Print top 10 most frequent words
    const to_show = @min(entries.items.len, 10);
    try out.print("top {d} words in {d} shards:\n", .{ to_show, parts.len });
    for (entries.items[0..to_show]) |e| {
        try out.print("{s} {d}\n", .{ e.k, e.v });
    }
    
    // Free duplicated keys now that we are done with the map
    var free_it = total.iterator();
    while (free_it.next()) |e| allocator.free(e.key_ptr.*);
    
    try out.flush();
}
