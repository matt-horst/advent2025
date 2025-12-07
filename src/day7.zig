const std = @import("std");
const AdventError = @import("root.zig").AdventError;

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
