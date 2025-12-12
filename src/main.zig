const std = @import("std");
const advent = @import("root.zig");
const day1 = @import("day1.zig");
const day2 = @import("day2.zig");
const day3 = @import("day3.zig");
const day4 = @import("day4.zig");
const day5 = @import("day5.zig");
const day6 = @import("day6.zig");
const day7 = @import("day7.zig");
const day8 = @import("day8.zig");
const day9 = @import("day9.zig");
const day10 = @import("day10.zig");
const day11 = @import("day11.zig");

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

    // Day 8
    var d8 = InnerArray{};
    defer d8.deinit(allocator);

    try d8.append(allocator, .{ .f = day8.part1, .file_path = "input/input_day8" });
    try d8.append(allocator, .{ .f = day8.part2, .file_path = "input/input_day8" });

    try days.append(allocator, d8);

    // Day 9
    var d9 = InnerArray{};
    defer d9.deinit(allocator);

    try d9.append(allocator, .{ .f = day9.part1, .file_path = "input/input_day9" });
    try d9.append(allocator, .{ .f = day9.part2, .file_path = "input/input_day9" });

    try days.append(allocator, d9);

    // Day 10
    var d10 = InnerArray{};
    defer d10.deinit(allocator);

    // try d10.append(allocator, .{ .f = day10.part1, .file_path = "input/input_day10" });
    try d10.append(allocator, .{ .f = day10.part2, .file_path = "input/input_day10" });

    try days.append(allocator, d10);

    // Day 11
    var d11 = InnerArray{};
    defer d11.deinit(allocator);

    try d11.append(allocator, .{ .f = day11.part1, .file_path = "input/input_day11" });
    try d11.append(allocator, .{ .f = day11.part2, .file_path = "input/input_day11" });

    try days.append(allocator, d11);

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

test {
    std.testing.refAllDecls(@This());
}
