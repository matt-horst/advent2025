const std = @import("std");
const advent = @import("advent");

pub fn part1(allocator: std.mem.Allocator, input: []const u8) advent.InputError![]const u8 {
    var count: u64 = 0;

    var it = std.mem.splitScalar(u8, input[0 .. input.len - 1], ',');
    while (it.next()) |pair| {
        const idx = std.mem.indexOfScalar(u8, pair, '-') orelse return advent.InputError.InvalidInput;
        const lhs = std.fmt.parseInt(usize, pair[0..idx], 10) catch return advent.InputError.InvalidInput;
        const rhs = std.fmt.parseInt(usize, pair[idx + 1 ..], 10) catch return advent.InputError.InvalidInput;

        const max_len = pair.len - idx - 1;

        var pattern_it = patterns().init(max_len / 2);
        while (pattern_it.next()) |p| {
            const pattern = p[0];
            const pattern_len = p[1];

            const val = repeat_pattern(pattern, pattern_len, 2);
            if (lhs <= val and val <= rhs) {
                count += val;
            }
        }
    }

    const ans = std.fmt.allocPrint(allocator, "{d}", .{count}) catch return advent.InputError.InvalidInput;
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

pub fn part2(allocator: std.mem.Allocator, input: []const u8) advent.InputError![]const u8 {
    var count: u64 = 0;
    var hm = std.AutoHashMap(usize, bool).init(allocator);
    defer hm.deinit();

    var it = std.mem.splitScalar(u8, input[0 .. input.len - 1], ',');
    while (it.next()) |pair| {
        const idx = std.mem.indexOfScalar(u8, pair, '-') orelse return advent.InputError.InvalidInput;
        const lhs = std.fmt.parseInt(usize, pair[0..idx], 10) catch return advent.InputError.InvalidInput;
        const rhs = std.fmt.parseInt(usize, pair[idx + 1 ..], 10) catch return advent.InputError.InvalidInput;

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

                hm.put(val, true) catch return advent.InputError.InvalidInput;
            }
        }
    }

    const ans = std.fmt.allocPrint(allocator, "{d}", .{count}) catch return advent.InputError.InvalidInput;
    return ans;
}
