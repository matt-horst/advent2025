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
