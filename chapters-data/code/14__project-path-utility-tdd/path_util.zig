const std = @import("std");

/// Tiny, allocator-friendly path utilities for didactic purposes.
/// Note: These do not attempt full platform semantics; they aim to be predictable
/// and portable for teaching. Prefer std.fs.path for production code.
pub const pathutil = struct {
    /// Join parts with exactly one separator between components.
    /// - Collapses duplicate separators at boundaries
    /// - Preserves a leading root (e.g. "/" on POSIX) if the first non-empty part starts with a separator
    /// - Does not resolve dot segments or drive letters
    pub fn joinAlloc(allocator: std.mem.Allocator, parts: []const []const u8) ![]u8 {
        var list: std.ArrayListUnmanaged(u8) = .{};
        defer list.deinit(allocator);

        const sep: u8 = std.fs.path.sep;
        var has_any: bool = false;

        for (parts) |raw| {
            if (raw.len == 0) continue;

            // Trim leading/trailing separators from this component
            var start: usize = 0;
            var end: usize = raw.len;
            while (start < end and isSep(raw[start])) start += 1;
            while (end > start and isSep(raw[end - 1])) end -= 1;

            const had_leading_sep = start > 0;
            const core = raw[start..end];

            if (!has_any) {
                if (had_leading_sep) {
                    // Preserve absolute root
                    try list.append(allocator, sep);
                    has_any = true;
                }
            } else {
                // Ensure exactly one separator between components if we have content already
                if (list.items.len == 0 or list.items[list.items.len - 1] != sep) {
                    try list.append(allocator, sep);
                }
            }

            if (core.len != 0) {
                try list.appendSlice(allocator, core);
                has_any = true;
            }
        }

        return list.toOwnedSlice(allocator);
    }

    /// Return the last path component. Trailing separators are ignored.
    /// Examples: "a/b/c" -> "c", "/a/b/" -> "b", "/" -> "/", "" -> "".
    pub fn basename(path: []const u8) []const u8 {
        if (path.len == 0) return path;

        // Skip trailing separators
        var end = path.len;
        while (end > 0 and isSep(path[end - 1])) end -= 1;
        if (end == 0) {
            // path was all separators; treat it as root
            return path[0..1];
        }

        // Find previous separator
        var i: isize = @intCast(end);
        while (i > 0) : (i -= 1) {
            if (isSep(path[@intCast(i - 1)])) break;
        }
        const start: usize = @intCast(i);
        return path[start..end];
    }

    /// Return the directory portion (without trailing separators).
    /// Examples: "a/b/c" -> "a/b", "a" -> ".", "/" -> "/".
    pub fn dirpath(path: []const u8) []const u8 {
        if (path.len == 0) return ".";

        // Skip trailing separators
        var end = path.len;
        while (end > 0 and isSep(path[end - 1])) end -= 1;
        if (end == 0) return path[0..1]; // all separators -> root

        // Find previous separator
        var i: isize = @intCast(end);
        while (i > 0) : (i -= 1) {
            const ch = path[@intCast(i - 1)];
            if (isSep(ch)) break;
        }
        if (i == 0) return ".";

        // Skip any trailing separators in the dir portion
        var d_end: usize = @intCast(i);
        while (d_end > 1 and isSep(path[d_end - 1])) d_end -= 1;
        if (d_end == 0) return path[0..1];
        return path[0..d_end];
    }

    /// Return the extension (without dot) of the last component or "" if none.
    /// Examples: "file.txt" -> "txt", "a.tar.gz" -> "gz", ".gitignore" -> "".
    pub fn extname(path: []const u8) []const u8 {
        const base = basename(path);
        if (base.len == 0) return base;
        if (base[0] == '.') {
            // Hidden file as first character '.' does not count as extension if there is no other dot
            if (std.mem.indexOfScalar(u8, base[1..], '.')) |idx2| {
                const idx = 1 + idx2;
                if (idx + 1 < base.len) return base[(idx + 1)..];
                return "";
            } else return "";
        }
        if (std.mem.lastIndexOfScalar(u8, base, '.')) |idx| {
            if (idx + 1 < base.len) return base[(idx + 1)..];
        }
        return "";
    }

    /// Return a newly-allocated path with the extension replaced by `new_ext` (no dot).
    /// If there is no existing extension, appends one if `new_ext` is non-empty.
    pub fn changeExtAlloc(allocator: std.mem.Allocator, path: []const u8, new_ext: []const u8) ![]u8 {
        const base = basename(path);
        const dir = dirpath(path);
        const sep: u8 = std.fs.path.sep;

        var base_core = base;
        if (std.mem.lastIndexOfScalar(u8, base, '.')) |idx| {
            if (!(idx == 0 and base[0] == '.')) {
                base_core = base[0..idx];
            }
        }

        const need_dot = new_ext.len != 0;
        const dir_has = dir.len != 0 and !(dir.len == 1 and dir[0] == '.' and base.len == path.len);
        // Compute length at runtime to avoid comptime_int dependency
        var new_len: usize = 0;
        if (dir_has) new_len += dir.len + 1;
        new_len += base_core.len;
        if (need_dot) new_len += 1 + new_ext.len;

        var out = try allocator.alloc(u8, new_len);
        errdefer allocator.free(out);

        var w: usize = 0;
        if (dir_has) {
            @memcpy(out[w..][0..dir.len], dir);
            w += dir.len;
            out[w] = sep;
            w += 1;
        }
        @memcpy(out[w..][0..base_core.len], base_core);
        w += base_core.len;
        if (need_dot) {
            out[w] = '.';
            w += 1;
            @memcpy(out[w..][0..new_ext.len], new_ext);
            w += new_ext.len;
        }
        return out;
    }
};

inline fn isSep(ch: u8) bool {
    return ch == std.fs.path.sep or isOtherSep(ch);
}

inline fn isOtherSep(ch: u8) bool {
    // Be forgiving in parsing: treat both '/' and '\\' as separators on any platform
    // but only emit std.fs.path.sep when joining.
    return ch == '/' or ch == '\\';
}
