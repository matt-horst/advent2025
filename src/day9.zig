const std = @import("std");
const advent = @import("root.zig");
const AdventError = advent.AdventError;

pub fn part1(allocator: std.mem.Allocator, input: []const u8) AdventError![]const u8 {
    var max: u64 = 0;
    var ps = std.ArrayList([2]i32){};
    defer ps.deinit(allocator);

    var it = std.mem.tokenizeScalar(u8, input, '\n');
    while (it.next()) |line| {
        var line_it = std.mem.tokenizeScalar(u8, line, ',');
        const x = std.fmt.parseInt(i32, line_it.next().?, 10) catch return AdventError.ParseError;
        const y = std.fmt.parseInt(i32, line_it.next().?, 10) catch return AdventError.ParseError;
        const p: [2]i32 = .{ x, y };

        ps.append(allocator, p) catch return AdventError.OutOfMemory;
    }

    for (0.., ps.items) |i, a| {
        for (ps.items[i+1..]) |b| {
            max = @max(max, area(a, b));
        }
    }

    const buf = std.fmt.allocPrint(allocator, "{d}", .{max}) catch return AdventError.OutOfMemory;
    return buf;
}

fn area(a: [2]i32, b: [2]i32) u64 {
    const dx: u64 = @abs(a[0] - b[0] + 1);
    const dy: u64 = @abs(a[1] - b[1] + 1);
    return dx * dy;
}

test "day 9 part 1" {
    const gpa = std.testing.allocator;

    const result = try advent.process_file(gpa, part1, "input/example_day9");
    defer gpa.free(result);

    try std.testing.expectEqualStrings("50", result);
}
