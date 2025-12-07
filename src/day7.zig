const std = @import("std");
const advent = @import("root.zig");
const AdventError = advent.AdventError;

pub fn part1(allocator: std.mem.Allocator, input: []const u8) AdventError![]const u8 {
    var it = std.mem.splitScalar(u8, input, '\n');
    const first_line = it.first();
    const width = first_line.len;
    const start = std.mem.indexOfScalar(u8, first_line, 'S') orelse return AdventError.ParseError;

    var prev: []Loc = allocator.alloc(Loc, width) catch return AdventError.OutOfMemory;
    defer allocator.free(prev);

    for (0..width) |i| {
        prev[i] = if (i == start) .beam else .empty;
    }

    var curr: []Loc = allocator.alloc(Loc, width) catch return AdventError.OutOfMemory;
    defer allocator.free(curr);

    var total: i32 = 0;

    print(prev);
    while (it.next()) |line| {
        for (0.., line) |i, c| {
            curr[i] = @enumFromInt(c);
        }

        for (0.., prev) |i, p| {
            if (p != .beam) continue;

            if (curr[i] == .empty) {
                curr[i] = .beam;
            } else if (curr[i] == .splitter) {
                var is_split = false;
                if (i > 0 and curr[i - 1] == .empty) {
                    is_split = true;
                    curr[i - 1] = .beam;
                }

                if (i < width and curr[i + 1] == .empty) {
                    is_split = true;
                    curr[i + 1] = .beam;
                }

                if (is_split) total += 1;
            }
        }
        const tmp = prev;
        prev = curr;
        curr = tmp;
        print(prev);
    }

    const buf = std.fmt.allocPrint(allocator, "{d}", .{total}) catch return AdventError.OutOfMemory;
    return buf;
}

const Loc = enum(u8) { empty = '.', beam = '|', splitter = '^' };

fn print(line: []const Loc) void {
    for (line) |c| {
        std.debug.print("{c}", .{@intFromEnum(c)});
    }
    std.debug.print("\n", .{});
}

pub fn part2(allocator: std.mem.Allocator, input: []const u8) AdventError![]const u8 {
    var it = std.mem.splitScalar(u8, input[0 .. input.len - 1], '\n');
    const first_line = it.first();
    const width = first_line.len;
    const start = std.mem.indexOfScalar(u8, first_line, 'S') orelse return AdventError.ParseError;

    var prev: []i64 = allocator.alloc(i64, width) catch return AdventError.OutOfMemory;
    defer allocator.free(prev);

    for (0..width) |i| {
        prev[i] = if (i == start) 1 else 0;
    }

    var curr: []i64 = allocator.alloc(i64, width) catch return AdventError.OutOfMemory;
    defer allocator.free(curr);

    print_part2(prev);
    while (it.next()) |line| {
        for (0.., line) |i, c| {
            curr[i] = switch (c) {
                '.' => 0,
                '^' => -1,
                else => return AdventError.ParseError,
            };
        }

        for (0.., prev) |i, p| {
            if (p <= 0) continue;

            if (curr[i] >= 0) {
                curr[i] += p;
            } else if (curr[i] < 0) {
                if (i > 0 and curr[i - 1] >= 0) {
                    curr[i - 1] += p;
                }

                if (i < width and curr[i + 1] >= 0) {
                    curr[i + 1] += p;
                }
            }
        }
        print_part2(curr);
        const tmp = prev;
        prev = curr;
        curr = tmp;
    }

    var total: i64 = 0;
    for (prev) |p| {
        if (p > 0) total += p;
    }

    const buf = std.fmt.allocPrint(allocator, "{d}", .{total}) catch return AdventError.OutOfMemory;
    return buf;
}

fn print_part2(line: []const i64) void {
    for (line) |c| {
        if (c == 0) {
            std.debug.print(".", .{});
        } else if (c == -1) {
            std.debug.print("^", .{});
        } else {
            std.debug.print("{d}", .{c});
        }
    }
    std.debug.print("\n", .{});
}

test "day7 part1 test" {
    const gpa = std.testing.allocator;

    const buf = try advent.read_file(gpa, "input/example_day7");
    defer gpa.free(buf);

    const result = try part1(gpa, buf);
    defer gpa.free(result);

    try std.testing.expectEqualStrings("21", result);
}

test "day7 part2 test" {
    const gpa = std.testing.allocator;

    const buf = try advent.read_file(gpa, "input/example_day7");
    defer gpa.free(buf);

    const result = try part2(gpa, buf);
    defer gpa.free(result);

    try std.testing.expectEqualStrings("40", result);
}
