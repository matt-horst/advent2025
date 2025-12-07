const std = @import("std");
const advent = @import("root.zig");
const AdventError = advent.AdventError;

pub fn part1(allocator: std.mem.Allocator, input: []const u8) AdventError![]const u8 {
    var total: i32 = 0;
    var map = std.ArrayList(std.ArrayList(u8)){};
    defer {
        for (0..map.items.len) |i| {
            map.items[i].deinit(allocator);
        }
        map.deinit(allocator);
    }

    var it = std.mem.splitScalar(u8, input[0 .. input.len - 1], '\n');
    while (it.next()) |line| {
        var item = std.ArrayList(u8){};
        for (line) |c| {
            item.append(allocator, c) catch return AdventError.OutOfMemory;
        }
        map.append(allocator, item) catch return AdventError.OutOfMemory;
    }

    const n = map.items.len;
    const m = map.items[0].items.len;
    for (0.., map.items) |i, row| {
        for (0.., row.items) |j, c| {
            if (c == '.') continue;
            var count: i32 = 0;
            for (0..3) |u| {
                for (0..3) |v| {
                    if (u == 1 and v == 1) continue;

                    const ii = @subWithOverflow(i + u, 1)[0];
                    const jj = @subWithOverflow(j + v, 1)[0];
                    if (0 <= ii and ii < n and 0 <= jj and jj < m and map.items[ii].items[jj] == '@') {
                        count += 1;
                    }
                }
            }

            if (count < 4) {
                total += 1;
            }
        }
    }

    const buf = std.fmt.allocPrint(allocator, "{d}", .{total}) catch return AdventError.OutOfMemory;
    return buf;
}

pub fn part2(allocator: std.mem.Allocator, input: []const u8) AdventError![]const u8 {
    var total: i32 = 0;
    var map = std.ArrayList(std.ArrayList(u8)){};
    defer {
        for (0..map.items.len) |i| {
            map.items[i].deinit(allocator);
        }
        map.deinit(allocator);
    }

    var it = std.mem.splitScalar(u8, input[0 .. input.len - 1], '\n');
    while (it.next()) |line| {
        var item = std.ArrayList(u8){};
        for (line) |c| {
            item.append(allocator, c) catch return AdventError.OutOfMemory;
        }
        map.append(allocator, item) catch return AdventError.OutOfMemory;
    }

    const n = map.items.len;
    const m = map.items[0].items.len;
    var sub_total: i32 = -1;
    while (sub_total != 0) {
        sub_total = 0;

        for (0.., map.items) |i, row| {
            for (0.., row.items) |j, c| {
                if (c == '.') continue;

                var count: i32 = 0;
                for (0..3) |u| {
                    for (0..3) |v| {
                        if (u == 1 and v == 1) continue;

                        const ii = @subWithOverflow(i + u, 1)[0];
                        const jj = @subWithOverflow(j + v, 1)[0];
                        if (0 <= ii and ii < n and 0 <= jj and jj < m and map.items[ii].items[jj] != '.') {
                            count += 1;
                        }
                    }
                }

                if (count < 4) {
                    map.items[i].items[j] = 'x';
                    sub_total += 1;
                }
            }
        }

        for (0.., map.items) |i, row| {
            for (0.., row.items) |j, c| {
                if (c == 'x') {
                    map.items[i].items[j] = '.';
                }
            }
        }

        total += sub_total;
    }

    const buf = std.fmt.allocPrint(allocator, "{d}", .{total}) catch return AdventError.OutOfMemory;
    return buf;
}

test "day4 part1 test" {
    const gpa = std.testing.allocator;

    const buf = try advent.read_file(gpa, "input/example_day4");
    defer gpa.free(buf);

    const result = try part1(gpa, buf);
    defer gpa.free(result);

    try std.testing.expectEqualStrings("13", result);
}

test "day4 part2 test" {
    const gpa = std.testing.allocator;

    const buf = try advent.read_file(gpa, "input/example_day4");
    defer gpa.free(buf);

    const result = try part2(gpa, buf);
    defer gpa.free(result);

    try std.testing.expectEqualStrings("43", result);
}
