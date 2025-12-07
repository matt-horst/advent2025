const std = @import("std");
const advent = @import("root.zig");
const AdventError = advent.AdventError;

pub fn part1(allocator: std.mem.Allocator, input: []const u8) AdventError![]const u8 {
    var sum: i32 = 0;

    var it = std.mem.splitScalar(u8, input, '\n');
    while (it.next()) |line| {
        var max_digit: i32 = 0;
        var max_num: i32 = 0;
        for (line) |c| {
            const v = c - '0';
            const num = max_digit * 10 + v;

            max_num = @max(max_num, num);
            max_digit = @max(max_digit, v);
        }

        sum += max_num;
    }

    const buf = std.fmt.allocPrint(allocator, "{d}", .{sum}) catch return AdventError.OutOfMemory;
    return buf;
}

pub fn part2(allocator: std.mem.Allocator, input: []const u8) AdventError![]const u8 {
    var sum: u64 = 0;

    var it = std.mem.splitScalar(u8, input, '\n');
    while (it.next()) |line| {
        var dp = allocator.alloc([12]u64, line.len + 1) catch return AdventError.OutOfMemory;
        defer allocator.free(dp);

        for (0..12) |i| {
            dp[0][i] = 0;
        }

        for (0.., line) |i, c| {
            const v = c - '0';
            dp[i + 1][0] = @max(dp[i][0], v);
            for (1..12) |j| {
                dp[i + 1][j] = @max(dp[i][j], dp[i][j - 1] * 10 + v);
            }
        }

        const joltage = dp[line.len][11];
        sum += joltage;
    }

    const buf = std.fmt.allocPrint(allocator, "{d}", .{sum}) catch return AdventError.OutOfMemory;
    return buf;
}

test "day3 part1 test" {
    const gpa = std.testing.allocator;

    const buf = try advent.read_file(gpa, "input/example_day3");
    defer gpa.free(buf);

    const result = try part1(gpa, buf);
    defer gpa.free(result);

    try std.testing.expectEqualStrings("357", result);
}

test "day3 part2 test" {
    const gpa = std.testing.allocator;

    const buf = try advent.read_file(gpa, "input/example_day3");
    defer gpa.free(buf);

    const result = try part2(gpa, buf);
    defer gpa.free(result);

    try std.testing.expectEqualStrings("3121910778619", result);
}
