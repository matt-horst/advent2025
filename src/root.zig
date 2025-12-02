const std = @import("std");

pub const InputError = error{InvalidInput};

pub fn day1Part1(allocator: std.mem.Allocator, input: []const u8) InputError![]const u8 {
    const range = 100;
    var position: i32 = 50;
    var count: i32 = 0;
    var it = std.mem.splitScalar(u8, input, '\n');
    while (it.next()) |line| {
        if (line.len == 0) {
            break;
        }

        const c = line[0];
        const n = std.fmt.parseInt(i32, line[1..], 10) catch {
            return InputError.InvalidInput;
        };
        switch (c) {
            'L' => {
                position = @rem(position - n, range);
            },
            'R' => {
                position = @rem(position + n, range);
            },
            else => {
                return InputError.InvalidInput;
            },
        }

        if (position == 0) {
            count += 1;
        }
    }

    const ans = std.fmt.allocPrint(allocator, "{d}", .{count}) catch return InputError.InvalidInput;
    return ans;
}

pub fn day1Part2(allocator: std.mem.Allocator, input: []const u8) InputError![]const u8 {
    const range = 100;
    var position: i32 = 50;
    var count: i32 = 0;
    var it = std.mem.splitScalar(u8, input, '\n');
    while (it.next()) |line| {
        if (line.len == 0) {
            break;
        }

        const c = line[0];
        const n = std.fmt.parseInt(i32, line[1..], 10) catch {
            return InputError.InvalidInput;
        };

        count += @divTrunc(n, range);
        switch (c) {
            'L' => {
                if (position == 0) {
                    position = range;
                }
                const after = position - @rem(n, range);

                if (after <= 0) {
                    count += 1;
                }
                position = @rem(after + range, range);
            },
            'R' => {
                const after = position + @rem(n, range);

                if (after >= range) {
                    count += 1;
                }

                position = @rem(after, range);
            },
            else => {
                return InputError.InvalidInput;
            },
        }
    }

    const ans = std.fmt.allocPrint(allocator, "{d}", .{count}) catch return InputError.InvalidInput;
    return ans;
}

pub fn day2Part1(allocator: std.mem.Allocator, input: []const u8) InputError![]const u8 {
    var count: u64 = 0;

    var it = std.mem.splitScalar(u8, input[0 .. input.len - 1], ',');
    while (it.next()) |pair| {
        const idx = std.mem.indexOfScalar(u8, pair, '-') orelse return InputError.InvalidInput;
        const lhs = std.fmt.parseInt(usize, pair[0..idx], 10) catch return InputError.InvalidInput;
        const rhs = std.fmt.parseInt(usize, pair[idx + 1 ..], 10) catch return InputError.InvalidInput;

        var buf: []u8 = std.heap.page_allocator.alloc(u8, pair.len - idx) catch return InputError.InvalidInput;
        for (lhs..rhs + 1) |i| {
            const curr = std.fmt.bufPrint(buf[0..], "{d}", .{i}) catch return InputError.InvalidInput;
            if (std.mem.eql(u8, curr[0 .. curr.len / 2], curr[curr.len / 2 ..])) {
                count += @intCast(i);
            }
        }
    }

    const ans = std.fmt.allocPrint(allocator, "{d}", .{count}) catch return InputError.InvalidInput;
    return ans;
}

fn patterns() type {
    return struct {
        max_len: usize,
        curr_len: usize,
        sentinel: u64,
        curr: u64,

        pub fn init(max_len: usize) @This() {
            return .{ .max_len = max_len, .curr = 1, .curr_len = 1, .sentinel = 10 };
        }

        pub fn next(self: *@This()) ?struct { u64, usize } {
            if (self.curr_len > self.max_len) {
                return null;
            }

            const val = self.curr;
            const len = self.curr_len;

            if (self.curr == self.sentinel - 1) {
                self.curr_len += 1;
                self.sentinel *= 10;
            }

            self.curr += 1;

            return .{ val, len };
        }
    };
}

fn repeat_pattern(pattern: u64, pattern_len: usize, count: usize) u64 {
    var total: u64 = 0;
    const shift: u64 = std.math.pow(u64, 10, pattern_len);

    for (0..count) |_| {
        total *= shift;
        total += pattern;
    }

    return total;
}

pub fn day2Part2(allocator: std.mem.Allocator, input: []const u8) InputError![]const u8 {
    var count: u64 = 0;
    var hm = std.AutoHashMap(usize, bool).init(allocator);
    defer hm.deinit();

    var it = std.mem.splitScalar(u8, input[0 .. input.len - 1], ',');
    while (it.next()) |pair| {
        const idx = std.mem.indexOfScalar(u8, pair, '-') orelse return InputError.InvalidInput;
        const lhs = std.fmt.parseInt(usize, pair[0..idx], 10) catch return InputError.InvalidInput;
        const rhs = std.fmt.parseInt(usize, pair[idx + 1 ..], 10) catch return InputError.InvalidInput;

        const max_len = pair.len - idx - 1;
        const min_len = idx;

        var pattern_it = patterns().init(max_len / 2);
        while (pattern_it.next()) |p| {
            const pattern = p[0];
            const pattern_len = p[1];

            var cnt = @max(pattern_len / min_len, 2);
            while (cnt * pattern_len <= max_len) {
                defer cnt += 1;
                const val = repeat_pattern(pattern, pattern_len, cnt);
                if (val < lhs) {
                    continue;
                }

                if (val > rhs) {
                    break;
                }

                if (hm.get(val)) |_| {
                    continue;
                }

                count += val;

                hm.put(val, true) catch return InputError.InvalidInput;
            }
        }
    }

    const ans = std.fmt.allocPrint(allocator, "{d}", .{count}) catch return InputError.InvalidInput;
    return ans;
}
