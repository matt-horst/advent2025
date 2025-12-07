const std = @import("std");
const advent = @import("root.zig");
const AdventError = advent.AdventError;

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

test "day1 part1 test" {
    const gpa = std.testing.allocator;

    const buf = try advent.read_file(gpa, "input/example_day1");
    defer gpa.free(buf);

    const result = try part1(gpa, buf);
    defer gpa.free(result);

    try std.testing.expectEqualStrings("3", result);
}

test "day1 part2 test" {
    const gpa = std.testing.allocator;

    const buf = try advent.read_file(gpa, "input/example_day1");
    defer gpa.free(buf);

    const result = try part2(gpa, buf);
    defer gpa.free(result);

    try std.testing.expectEqualStrings("6", result);
}
