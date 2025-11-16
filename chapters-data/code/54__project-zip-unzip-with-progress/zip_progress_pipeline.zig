const std = @import("std");

const SampleFile = struct {
    path: []const u8,
    contents: []const u8,
};

const sample_files = [_]SampleFile{
    .{ .path = "input/metrics.txt", .contents = "uptime=420s\nrequests=1312\nerrors=3\n" },
    .{ .path = "input/inventory.json", .contents = "{\n  \"service\": \"telemetry\",\n  \"shards\": [\"alpha\", \"beta\", \"gamma\"]\n}\n" },
    .{ .path = "input/logs/app.log", .contents = "[info] ingest started\n[warn] queue delay=87ms\n[info] ingest completed\n" },
    .{ .path = "input/README.md", .contents = "# Telemetry bundle\n\nSynthetic records used for the zip/unzip progress demo.\n" },
};

const EntryMetrics = struct {
    crc32: u32,
    size: usize,
};

const BuildSummary = struct {
    bytes_written: usize,
    sha256: [32]u8,
};

const VerifySummary = struct {
    files_checked: usize,
    total_bytes: usize,
    extracted_root: []const u8,
    owns_root: bool,
};

const archive_path = "artifact/telemetry.zip";
const extract_root = "replay";

fn seedSamples(dir: std.fs.Dir, progress: *std.Progress.Node) !struct { files: usize, bytes: usize } {
    var total_bytes: usize = 0;
    for (sample_files) |sample| {
        if (std.fs.path.dirname(sample.path)) |parent| {
            try dir.makePath(parent);
        }
        var file = try dir.createFile(sample.path, .{ .truncate = true });
        defer file.close();
        try file.writeAll(sample.contents);
        total_bytes += sample.contents.len;
        progress.completeOne();
    }
    return .{ .files = sample_files.len, .bytes = total_bytes };
}

const EntryRecord = struct {
    name: []const u8,
    crc32: u32,
    size: u32,
    offset: u32,
};

fn makeLocalHeader(name_len: u16, crc32: u32, size: u32) [30]u8 {
    var header: [30]u8 = undefined;
    header[0] = 'P';
    header[1] = 'K';
    header[2] = 3;
    header[3] = 4;
    std.mem.writeInt(u16, header[4..6], 20, .little);
    std.mem.writeInt(u16, header[6..8], 0, .little);
    std.mem.writeInt(u16, header[8..10], 0, .little);
    std.mem.writeInt(u16, header[10..12], 0, .little);
    std.mem.writeInt(u16, header[12..14], 0, .little);
    std.mem.writeInt(u32, header[14..18], crc32, .little);
    std.mem.writeInt(u32, header[18..22], size, .little);
    std.mem.writeInt(u32, header[22..26], size, .little);
    std.mem.writeInt(u16, header[26..28], name_len, .little);
    std.mem.writeInt(u16, header[28..30], 0, .little);
    return header;
}

fn makeCentralHeader(entry: EntryRecord) [46]u8 {
    var header: [46]u8 = undefined;
    header[0] = 'P';
    header[1] = 'K';
    header[2] = 1;
    header[3] = 2;
    std.mem.writeInt(u16, header[4..6], 0x0314, .little);
    std.mem.writeInt(u16, header[6..8], 20, .little);
    std.mem.writeInt(u16, header[8..10], 0, .little);
    std.mem.writeInt(u16, header[10..12], 0, .little);
    std.mem.writeInt(u16, header[12..14], 0, .little);
    std.mem.writeInt(u16, header[14..16], 0, .little);
    std.mem.writeInt(u32, header[16..20], entry.crc32, .little);
    std.mem.writeInt(u32, header[20..24], entry.size, .little);
    std.mem.writeInt(u32, header[24..28], entry.size, .little);
    const name_len_u16 = @as(u16, @intCast(entry.name.len));
    std.mem.writeInt(u16, header[28..30], name_len_u16, .little);
    std.mem.writeInt(u16, header[30..32], 0, .little);
    std.mem.writeInt(u16, header[32..34], 0, .little);
    std.mem.writeInt(u16, header[34..36], 0, .little);
    std.mem.writeInt(u16, header[36..38], 0, .little);
    const unix_mode: u32 = 0o100644 << 16;
    std.mem.writeInt(u32, header[38..42], unix_mode, .little);
    std.mem.writeInt(u32, header[42..46], entry.offset, .little);
    return header;
}

fn makeEndRecord(cd_size: u32, cd_offset: u32, entry_count: u16) [22]u8 {
    var footer: [22]u8 = undefined;
    footer[0] = 'P';
    footer[1] = 'K';
    footer[2] = 5;
    footer[3] = 6;
    std.mem.writeInt(u16, footer[4..6], 0, .little);
    std.mem.writeInt(u16, footer[6..8], 0, .little);
    std.mem.writeInt(u16, footer[8..10], entry_count, .little);
    std.mem.writeInt(u16, footer[10..12], entry_count, .little);
    std.mem.writeInt(u32, footer[12..16], cd_size, .little);
    std.mem.writeInt(u32, footer[16..20], cd_offset, .little);
    std.mem.writeInt(u16, footer[20..22], 0, .little);
    return footer;
}

fn buildArchive(
    allocator: std.mem.Allocator,
    dir: std.fs.Dir,
    metrics: *std.StringHashMap(EntryMetrics),
    progress: *std.Progress.Node,
) !BuildSummary {
    if (std.fs.path.dirname(archive_path)) |parent| {
        try dir.makePath(parent);
    }
    var entries = try std.ArrayList(EntryRecord).initCapacity(allocator, sample_files.len);
    defer entries.deinit(allocator);

    try metrics.ensureTotalCapacity(sample_files.len);

    var blob: std.ArrayList(u8) = .empty;
    defer blob.deinit(allocator);

    for (sample_files) |sample| {
        if (sample.path.len > std.math.maxInt(u16)) return error.NameTooLong;

        var file = try dir.openFile(sample.path, .{});
        defer file.close();

        const max_len = 64 * 1024;
        const data = try file.readToEndAlloc(allocator, max_len);
        defer allocator.free(data);

        if (data.len > std.math.maxInt(u32)) return error.InputTooLarge;
        if (blob.items.len > std.math.maxInt(u32)) return error.ArchiveTooLarge;

        var crc = std.hash.crc.Crc32.init();
        crc.update(data);
        const digest = crc.final();

        const offset_u32 = @as(u32, @intCast(blob.items.len));
        const size_u32 = @as(u32, @intCast(data.len));
        const name_len_u16 = @as(u16, @intCast(sample.path.len));

        const header = makeLocalHeader(name_len_u16, digest, size_u32);
        try blob.appendSlice(allocator, header[0..]);
        try blob.appendSlice(allocator, sample.path);
        try blob.appendSlice(allocator, data);

        try entries.append(allocator, .{
            .name = sample.path,
            .crc32 = digest,
            .size = size_u32,
            .offset = offset_u32,
        });

        const gop = try metrics.getOrPut(sample.path);
        if (!gop.found_existing) {
            gop.key_ptr.* = try allocator.dupe(u8, sample.path);
        }
        gop.value_ptr.* = .{ .crc32 = digest, .size = data.len };

        progress.completeOne();
    }

    const central_offset_usize = blob.items.len;
    if (central_offset_usize > std.math.maxInt(u32)) return error.ArchiveTooLarge;
    const central_offset = @as(u32, @intCast(central_offset_usize));

    for (entries.items) |entry| {
        const header = makeCentralHeader(entry);
        try blob.appendSlice(allocator, header[0..]);
        try blob.appendSlice(allocator, entry.name);
    }

    const central_size = @as(u32, @intCast(blob.items.len - central_offset_usize));
    const footer = makeEndRecord(central_size, central_offset, @as(u16, @intCast(entries.items.len)));
    try blob.appendSlice(allocator, footer[0..]);

    var zip_file = try dir.createFile(archive_path, .{ .truncate = true, .read = true });
    defer zip_file.close();
    try zip_file.writeAll(blob.items);

    var sha256 = std.crypto.hash.sha2.Sha256.init(.{});
    sha256.update(blob.items);
    var digest_bytes: [32]u8 = undefined;
    sha256.final(&digest_bytes);

    return .{ .bytes_written = blob.items.len, .sha256 = digest_bytes };
}

fn extractAndVerify(
    allocator: std.mem.Allocator,
    dir: std.fs.Dir,
    metrics: *const std.StringHashMap(EntryMetrics),
    progress: *std.Progress.Node,
) !VerifySummary {
    try dir.makePath(extract_root);
    var dest_dir = try dir.openDir(extract_root, .{ .access_sub_paths = true, .iterate = true });
    defer dest_dir.close();

    var file = try dir.openFile(archive_path, .{});
    defer file.close();

    var read_buf: [4096]u8 = undefined;
    var reader = file.reader(&read_buf);

    var diagnostics = std.zip.Diagnostics{ .allocator = allocator };
    defer diagnostics.deinit();

    try std.zip.extract(dest_dir, &reader, .{ .diagnostics = &diagnostics });

    var files_checked: usize = 0;
    var total_bytes: usize = 0;

    for (sample_files) |sample| {
        var out_file = try dest_dir.openFile(sample.path, .{});
        defer out_file.close();
        const data = try out_file.readToEndAlloc(allocator, 64 * 1024);
        defer allocator.free(data);

        const expected = metrics.get(sample.path) orelse return error.ExpectedEntryMissing;
        var crc = std.hash.crc.Crc32.init();
        crc.update(data);
        if (crc.final() != expected.crc32 or data.len != expected.size) {
            return error.VerificationFailed;
        }
        files_checked += 1;
        total_bytes += data.len;
        progress.completeOne();
    }

    var result_root: []const u8 = "<scattered>";
    var owns_root = false;
    if (diagnostics.root_dir.len > 0) {
        result_root = try allocator.dupe(u8, diagnostics.root_dir);
        owns_root = true;
    }
    return .{
        .files_checked = files_checked,
        .total_bytes = total_bytes,
        .extracted_root = result_root,
        .owns_root = owns_root,
    };
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const leak_status = gpa.deinit();
        std.debug.assert(leak_status == .ok);
    }
    const allocator = gpa.allocator();

    var stdout_buffer: [512]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const out = &stdout_writer.interface;

    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    var metrics = std.StringHashMap(EntryMetrics).init(allocator);
    defer {
        var it = metrics.iterator();
        while (it.next()) |kv| {
            allocator.free(kv.key_ptr.*);
        }
        metrics.deinit();
    }

    var progress_root = std.Progress.start(.{
        .root_name = "zip-pipeline",
        .estimated_total_items = 3,
        .disable_printing = true,
    });
    defer progress_root.end();

    var stage_seed = progress_root.start("seed", sample_files.len);
    const seeded = try seedSamples(tmp.dir, &stage_seed);
    stage_seed.end();
    try out.print("[1/3] seeded samples -> files={d}, bytes={d}\n", .{ seeded.files, seeded.bytes });

    var stage_build = progress_root.start("build", sample_files.len);
    const build_summary = try buildArchive(allocator, tmp.dir, &metrics, &stage_build);
    stage_build.end();

    const hex_digest = std.fmt.bytesToHex(build_summary.sha256, .lower);
    try out.print("[2/3] built archive -> bytes={d}\n    sha256={s}\n", .{ build_summary.bytes_written, hex_digest[0..] });

    var stage_verify = progress_root.start("verify", sample_files.len);
    const verify_summary = try extractAndVerify(allocator, tmp.dir, &metrics, &stage_verify);
    stage_verify.end();
    defer if (verify_summary.owns_root) allocator.free(verify_summary.extracted_root);
    try out.print(
        "[3/3] extracted + verified -> files={d}, bytes={d}, root={s}\n",
        .{ verify_summary.files_checked, verify_summary.total_bytes, verify_summary.extracted_root },
    );

    try out.flush();
}
