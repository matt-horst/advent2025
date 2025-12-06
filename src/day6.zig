const std = @import("std");
const AdventError = @import("root.zig").AdventError;

pub fn part1(allocator: std.mem.Allocator, input: []const u8) AdventError![]const u8 {
    var it = std.mem.splitBackwardsScalar(u8, input[0 .. input.len - 1], '\n');
    const ops_line = it.first();

    var ops_list = std.ArrayList(Op){};
    defer ops_list.deinit(allocator);

    var ops_it = std.mem.tokenizeScalar(u8, ops_line, ' ');
    while (ops_it.next()) |item| {
        if (item.len != 1) {
            return AdventError.ParseError;
        }

        const op: Op = switch (item[0]) {
            '+' => .add,
            '*' => .mul,
            else => return AdventError.ParseError,
        };

        ops_list.append(allocator, op) catch return AdventError.OutOfMemory;
    }

    var totals = allocator.alloc(u64, ops_list.items.len) catch return AdventError.OutOfMemory;
    defer allocator.free(totals);
    for (0.., ops_list.items) |i, op| {
        switch (op) {
            .add => totals[i] = 0,
            .mul => totals[i] = 1,
        }
    }

    while (it.next()) |line| {
        var line_it = std.mem.tokenizeScalar(u8, line, ' ');
        var i: usize = 0;
        while (line_it.next()) |item| {
            const value = std.fmt.parseInt(u64, item, 10) catch return AdventError.ParseError;
            switch (ops_list.items[i]) {
                .add => totals[i] += value,
                .mul => totals[i] *= value,
            }
            i += 1;
        }
    }

    var total: u64 = 0;
    for (totals) |v| {
        total += v;
    }

    const buf = std.fmt.allocPrint(allocator, "{d}", .{total}) catch return AdventError.OutOfMemory;
    return buf;
}

pub fn part2(allocator: std.mem.Allocator, input: []const u8) AdventError![]const u8 {
    var it = std.mem.splitBackwardsScalar(u8, input[0 .. input.len - 1], '\n');
    const ops_line = it.first();

    var ops_list = std.ArrayList(Op){};
    defer ops_list.deinit(allocator);

    var widths = std.ArrayList(usize){};
    defer widths.deinit(allocator);

    var ops_it = std.mem.splitScalar(u8, ops_line, ' ');
    var curr_width: usize = 0;
    while (ops_it.next()) |item| {
        if (item.len == 0) {
            curr_width += 1;
            continue;
        } else {
            if (curr_width != 0) {
                widths.append(allocator, curr_width) catch return AdventError.OutOfMemory;
            }
            curr_width = 1;
        }

        const op: Op = switch (item[0]) {
            '+' => .add,
            '*' => .mul,
            else => return AdventError.ParseError,
        };

        ops_list.append(allocator, op) catch return AdventError.OutOfMemory;
    }
    widths.append(allocator, curr_width) catch return AdventError.OutOfMemory;

    var numbers = allocator.alloc([]u64, ops_list.items.len) catch return AdventError.OutOfMemory;
    defer {
        for (numbers) |num| {
            allocator.free(num);
        }
        allocator.free(numbers);
    }

    for (0.., widths.items) |i, w| {
        numbers[i] = allocator.alloc(u64, w) catch return AdventError.OutOfMemory;
        for (0.., numbers[i]) |j, _| {
            numbers[i][j] = 0;
        }
    }

    const rest = it.rest();
    var rest_it = std.mem.splitScalar(u8, rest, '\n');
    while (rest_it.next()) |line| {
        var i: usize = 0;
        var j: usize = 0;

        for (line) |c| {
            if (j < widths.items[i]) {
                if (std.ascii.isDigit(c)) {
                    numbers[i][j] *= 10;
                    numbers[i][j] += c - '0';
                }

                j += 1;
            } else {
                i += 1;
                j = 0;
                continue;
            }
        }
    }

    var total: u64 = 0;
    for (0.., numbers) |i, blk| {
        const op = ops_list.items[i];
        var sub_total: u64 = switch (op) {
            .add => 0,
            .mul => 1,
        };

        for (blk) |v| {
            switch (op) {
                .add => sub_total += v,
                .mul => sub_total *= v,
            }
        }

        total += sub_total;
    }

    const buf = std.fmt.allocPrint(allocator, "{d}", .{total}) catch return AdventError.OutOfMemory;
    return buf;
}

const Op = enum(u8) { add = '+', mul = '*' };
