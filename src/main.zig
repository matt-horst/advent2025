const std = @import("std");
const advent = @import("root.zig");
const day1 = @import("day1.zig");
const day2 = @import("day2.zig");
const day3 = @import("day3.zig");
const day4 = @import("day4.zig");
const day5 = @import("day5.zig");
const day6 = @import("day6.zig");
const day7 = @import("day7.zig");

const Arg = enum {
    day,
    part,
    none,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stdout_buf: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buf);
    const stdout = &stdout_writer.interface;
    defer stdout.flush() catch |err| std.debug.print("failed to flush stdout: {any}\n", .{err});

    var it = std.process.args();
    var kind = Arg.none;
    var day: i32 = -1;
    var part: i32 = -1;

    _ = it.next();
    while (it.next()) |arg| {
        switch (kind) {
            .none => {
                if (std.mem.eql(u8, arg, "--day")) {
                    kind = .day;
                } else if (std.mem.eql(u8, arg, "--part")) {
                    kind = .part;
                }
            },
            .day => {
                day = try std.fmt.parseInt(i32, arg, 10);
                kind = .none;
            },
            .part => {
                part = try std.fmt.parseInt(i32, arg, 10);
                kind = .none;
            },
        }
    }

    const InnerArray = std.ArrayList(struct { f: *const advent.AdventFn, file_path: []const u8 });
    var days = std.ArrayList(InnerArray){};
    defer days.deinit(allocator);

    // Day 1
    var d1 = InnerArray{};
    defer d1.deinit(allocator);

    try d1.append(allocator, .{ .f = day1.part1, .file_path = "input/input_day1" });
    try d1.append(allocator, .{ .f = day1.part2, .file_path = "input/input_day1" });

    try days.append(allocator, d1);

    // Day 2
    var d2 = InnerArray{};
    defer d2.deinit(allocator);

    try d2.append(allocator, .{ .f = day2.part1, .file_path = "input/input_day2" });
    try d2.append(allocator, .{ .f = day2.part2, .file_path = "input/input_day2" });

    try days.append(allocator, d2);

    // Day 3
    var d3 = InnerArray{};
    defer d3.deinit(allocator);

    try d3.append(allocator, .{ .f = day3.part1, .file_path = "input/input_day3" });
    try d3.append(allocator, .{ .f = day3.part2, .file_path = "input/input_day3" });

    try days.append(allocator, d3);

    // Day 4
    var d4 = InnerArray{};
    defer d4.deinit(allocator);

    try d4.append(allocator, .{ .f = day4.part1, .file_path = "input/input_day4" });
    try d4.append(allocator, .{ .f = day4.part2, .file_path = "input/input_day4" });

    try days.append(allocator, d4);

    // Day 5
    var d5 = InnerArray{};
    defer d5.deinit(allocator);

    try d5.append(allocator, .{ .f = day5.part1, .file_path = "input/input_day5" });
    try d5.append(allocator, .{ .f = day5.part2, .file_path = "input/input_day5" });

    try days.append(allocator, d5);

    // Day 6
    var d6 = InnerArray{};
    defer d6.deinit(allocator);

    try d6.append(allocator, .{ .f = day6.part1, .file_path = "input/input_day6" });
    try d6.append(allocator, .{ .f = day6.part2, .file_path = "input/input_day6" });

    try days.append(allocator, d6);

    // Day 7
    var d7 = InnerArray{};
    defer d7.deinit(allocator);

    try d7.append(allocator, .{ .f = day7.part1, .file_path = "input/input_day7" });
    try d7.append(allocator, .{ .f = day7.part2, .file_path = "input/input_day7" });

    try days.append(allocator, d7);

    const day_start: usize = if (day < 0) 0 else @intCast(day - 1);
    const day_end: usize = if (day < 0) days.items.len else @intCast(day);
    for (day_start + 1.., days.items[day_start..day_end]) |i, d| {
        try stdout.print("Day {d}\n", .{i});

        const part_start: usize = if (part < 0) 0 else @intCast(part - 1);
        const part_end: usize = if (part < 0) d.items.len else @intCast(part);
        for (part_start + 1.., d.items[part_start..part_end]) |j, p| {
            const result = advent.process_file(allocator, p.f, p.file_path) catch |err| {
                std.debug.print("error: {any}\n", .{err});
                continue;
            };
            defer allocator.free(result);

            try stdout.print("- Part {d}: {s}\n", .{ j, result });
        }
        try stdout.print("\n", .{});
    }
}

test "day1 part1 test" {
    const gpa = std.testing.allocator;

    const buf = try advent.read_file(gpa, "input/example_day1");
    defer gpa.free(buf);

    const result = try day1.part1(gpa, buf);
    defer gpa.free(result);

    try std.testing.expectEqualStrings("3", result);
}

test "day1 part2 test" {
    const gpa = std.testing.allocator;

    const buf = try advent.read_file(gpa, "input/example_day1");
    defer gpa.free(buf);

    const result = try day1.part2(gpa, buf);
    defer gpa.free(result);

    try std.testing.expectEqualStrings("6", result);
}

test "day2 part1 test" {
    const gpa = std.testing.allocator;

    const buf = try advent.read_file(gpa, "input/example_day2");
    defer gpa.free(buf);

    const result = try day2.part1(gpa, buf);
    defer gpa.free(result);

    try std.testing.expectEqualStrings("1227775554", result);
}

test "day2 part2 test" {
    const gpa = std.testing.allocator;

    const buf = try advent.read_file(gpa, "input/example_day2");
    defer gpa.free(buf);

    const result = try day2.part2(gpa, buf);
    defer gpa.free(result);

    try std.testing.expectEqualStrings("4174379265", result);
}

test "day3 part1 test" {
    const gpa = std.testing.allocator;

    const buf = try advent.read_file(gpa, "input/example_day3");
    defer gpa.free(buf);

    const result = try day3.part1(gpa, buf);
    defer gpa.free(result);

    try std.testing.expectEqualStrings("357", result);
}

test "day3 part2 test" {
    const gpa = std.testing.allocator;

    const buf = try advent.read_file(gpa, "input/example_day3");
    defer gpa.free(buf);

    const result = try day3.part2(gpa, buf);
    defer gpa.free(result);

    try std.testing.expectEqualStrings("3121910778619", result);
}

test "day4 part1 test" {
    const gpa = std.testing.allocator;

    const buf = try advent.read_file(gpa, "input/example_day4");
    defer gpa.free(buf);

    const result = try day4.part1(gpa, buf);
    defer gpa.free(result);

    try std.testing.expectEqualStrings("13", result);
}

test "day4 part2 test" {
    const gpa = std.testing.allocator;

    const buf = try advent.read_file(gpa, "input/example_day4");
    defer gpa.free(buf);

    const result = try day4.part2(gpa, buf);
    defer gpa.free(result);

    try std.testing.expectEqualStrings("43", result);
}

test "day5 part1 test" {
    const gpa = std.testing.allocator;

    const buf = try advent.read_file(gpa, "input/example_day5");
    defer gpa.free(buf);

    const result = try day5.part1(gpa, buf);
    defer gpa.free(result);

    try std.testing.expectEqualStrings("3", result);
}

test "day5 part2 test" {
    const gpa = std.testing.allocator;

    const buf = try advent.read_file(gpa, "input/example_day5");
    defer gpa.free(buf);

    const result = try day5.part2(gpa, buf);
    defer gpa.free(result);

    try std.testing.expectEqualStrings("14", result);
}

test "day6 part1 test" {
    const gpa = std.testing.allocator;

    const buf = try advent.read_file(gpa, "input/example_day6");
    defer gpa.free(buf);

    const result = try day6.part1(gpa, buf);
    defer gpa.free(result);

    try std.testing.expectEqualStrings("4277556", result);
}

test "day6 part2 test" {
    const gpa = std.testing.allocator;

    const buf = try advent.read_file(gpa, "input/example_day6");
    defer gpa.free(buf);

    const result = try day6.part2(gpa, buf);
    defer gpa.free(result);

    try std.testing.expectEqualStrings("3263827", result);
}

test "day7 part1 test" {
    const gpa = std.testing.allocator;

    const buf = try advent.read_file(gpa, "input/example_day7");
    defer gpa.free(buf);

    const result = try day7.part1(gpa, buf);
    defer gpa.free(result);

    try std.testing.expectEqualStrings("21", result);
}

test "day7 part2 test" {
    const gpa = std.testing.allocator;

    const buf = try advent.read_file(gpa, "input/example_day7");
    defer gpa.free(buf);

    const result = try day7.part2(gpa, buf);
    defer gpa.free(result);

    try std.testing.expectEqualStrings("40", result);
}
