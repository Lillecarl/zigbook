const std = @import("std");

fn stdout() *std.Io.Writer {
    const g = struct {
        var buf: [2048]u8 = undefined;
        var w = std.fs.File.stdout().writer(&buf);
    };
    return &g.w.interface;
}

const Person = struct {
    id: u32,
    name: []const u8,
    active: bool = true,
};

pub fn main() !void {
    const out = stdout();

    // Reflect over Person using @TypeOf and @typeInfo
    const T = Person;
    try out.print("type name: {s}\n", .{@typeName(T)});

    const info = @typeInfo(T);
    switch (info) {
        .@"struct" => |s| {
            try out.print("fields: {d}\n", .{s.fields.len});
            inline for (s.fields, 0..) |f, idx| {
                try out.print("  {d}. {s}: {s}\n", .{ idx, f.name, @typeName(f.type) });
            }
        },
        else => try out.print("not a struct\n", .{}),
    }

    // Use reflection to initialize a default instance (here trivial)
    const p = Person{ .id = 42, .name = "Zig" };
    try out.print("example: id={} name={s} active={}\n", .{ p.id, p.name, p.active });

    try out.flush();
}
