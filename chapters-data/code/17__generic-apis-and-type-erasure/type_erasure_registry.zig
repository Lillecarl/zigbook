const std = @import("std");

const VTable = struct {
    name: []const u8,
    process: *const fn (*anyopaque, []const u8) void,
    finish: *const fn (*anyopaque) anyerror!void,
};

fn statePtr(comptime T: type, ptr: *anyopaque) *T {
    const aligned = @as(*align(@alignOf(T)) anyopaque, @alignCast(ptr));
    return @as(*T, @ptrCast(aligned));
}

fn stateConstPtr(comptime T: type, ptr: *anyopaque) *const T {
    const aligned = @as(*align(@alignOf(T)) anyopaque, @alignCast(ptr));
    return @as(*const T, @ptrCast(aligned));
}

const Processor = struct {
    state: *anyopaque,
    vtable: *const VTable,

    pub fn name(self: *const Processor) []const u8 {
        return self.vtable.name;
    }

    pub fn process(self: *Processor, text: []const u8) void {
        _ = @call(.auto, self.vtable.process, .{ self.state, text });
    }

    pub fn finish(self: *Processor) !void {
        try @call(.auto, self.vtable.finish, .{self.state});
    }
};

const CharTallyState = struct {
    vowels: usize,
    digits: usize,
};

fn charTallyProcess(state_ptr: *anyopaque, text: []const u8) void {
    const state = statePtr(CharTallyState, state_ptr);
    for (text) |byte| {
        if (std.ascii.isAlphabetic(byte)) {
            const lower = std.ascii.toLower(byte);
            switch (lower) {
                'a', 'e', 'i', 'o', 'u' => state.vowels += 1,
                else => {},
            }
        }
        if (std.ascii.isDigit(byte)) {
            state.digits += 1;
        }
    }
}

fn charTallyFinish(state_ptr: *anyopaque) !void {
    const state = stateConstPtr(CharTallyState, state_ptr);
    std.debug.print(
        "[{s}] vowels={d} digits={d}\n",
        .{ char_tally_vtable.name, state.vowels, state.digits },
    );
}

const char_tally_vtable = VTable{
    .name = "char-tally",
    .process = &charTallyProcess,
    .finish = &charTallyFinish,
};

fn makeCharTally(allocator: std.mem.Allocator) !Processor {
    const state = try allocator.create(CharTallyState);
    state.* = .{ .vowels = 0, .digits = 0 };
    return .{ .state = state, .vtable = &char_tally_vtable };
}

const WordStatsState = struct {
    total_chars: usize,
    sentences: usize,
    longest_word: usize,
    current_word: usize,
};

fn wordStatsProcess(state_ptr: *anyopaque, text: []const u8) void {
    const state = statePtr(WordStatsState, state_ptr);
    for (text) |byte| {
        state.total_chars += 1;
        if (byte == '.' or byte == '!' or byte == '?') {
            state.sentences += 1;
        }
        if (std.ascii.isAlphanumeric(byte)) {
            state.current_word += 1;
            if (state.current_word > state.longest_word) {
                state.longest_word = state.current_word;
            }
        } else if (state.current_word != 0) {
            state.current_word = 0;
        }
    }
}

fn wordStatsFinish(state_ptr: *anyopaque) !void {
    const state = statePtr(WordStatsState, state_ptr);
    if (state.current_word > state.longest_word) {
        state.longest_word = state.current_word;
    }
    std.debug.print(
        "[{s}] chars={d} sentences={d} longest-word={d}\n",
        .{ word_stats_vtable.name, state.total_chars, state.sentences, state.longest_word },
    );
}

const word_stats_vtable = VTable{
    .name = "word-stats",
    .process = &wordStatsProcess,
    .finish = &wordStatsFinish,
};

fn makeWordStats(allocator: std.mem.Allocator) !Processor {
    const state = try allocator.create(WordStatsState);
    state.* = .{ .total_chars = 0, .sentences = 0, .longest_word = 0, .current_word = 0 };
    return .{ .state = state, .vtable = &word_stats_vtable };
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();
    const allocator = arena.allocator();

    var processors = [_]Processor{
        try makeCharTally(allocator),
        try makeWordStats(allocator),
    };

    const samples = [_][]const u8{
        "Generic APIs feel like contracts.",
        "Type erasure lets us pass handles without templating everything.",
    };

    for (samples) |line| {
        for (&processors) |*processor| {
            processor.process(line);
        }
    }

    for (&processors) |*processor| {
        try processor.finish();
    }
}
