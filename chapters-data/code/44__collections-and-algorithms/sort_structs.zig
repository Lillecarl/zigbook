const std = @import("std");

const Person = struct {
    name: []const u8,
    age: u32,
};

fn byAge(context: void, a: Person, b: Person) bool {
    _ = context;
    return a.age < b.age;
}

pub fn main() !void {
    var people = [_]Person{
        .{ .name = "Alice", .age = 30 },
        .{ .name = "Bob", .age = 25 },
        .{ .name = "Charlie", .age = 35 },
    };

    std.sort.pdq(Person, &people, {}, byAge);

    std.debug.print("Sorted by age:\n", .{});
    for (people) |person| {
        std.debug.print("{s}, age {d}\n", .{ person.name, person.age });
    }
}
