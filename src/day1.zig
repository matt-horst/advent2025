const std = @import("std");
const AdventError = @import("root.zig").AdventError;

pub fn part1(allocator: std.mem.Allocator, input: []const u8) AdventError![]const u8 {
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
            return AdventError.ParseError;
        };
        switch (c) {
            'L' => {
                position = @rem(position - n, range);
            },
            'R' => {
                position = @rem(position + n, range);
            },
            else => {
                return AdventError.ParseError;
            },
        }

        if (position == 0) {
            count += 1;
        }
    }

    const ans = std.fmt.allocPrint(allocator, "{d}", .{count}) catch return AdventError.OutOfMemory;
    return ans;
}

pub fn part2(allocator: std.mem.Allocator, input: []const u8) AdventError![]const u8 {
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
            return AdventError.ParseError;
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
                return AdventError.ParseError;
            },
        }
    }

    const ans = std.fmt.allocPrint(allocator, "{d}", .{count}) catch return AdventError.OutOfMemory;
    return ans;
}
