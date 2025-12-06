const std = @import("std");
const advent = @import("root.zig");

pub fn part1(allocator: std.mem.Allocator, input: []const u8) advent.InputError![]const u8 {
    var it = std.mem.splitBackwardsScalar(u8, input[0 .. input.len - 1], '\n');
    const ops_line = it.first();

    var ops_list = std.ArrayList(Op){};
    defer ops_list.deinit(allocator);

    var ops_it = std.mem.tokenizeScalar(u8, ops_line, ' ');
    while (ops_it.next()) |item| {
        var op: Op = undefined;
        if (std.mem.eql(u8, item, "+")) {
            op = .add;
        } else if (std.mem.eql(u8, item, "*")) {
            // } else {
            op = .mul;
        } else {
            return advent.InputError.InvalidInput;
        }
        ops_list.append(allocator, op) catch return advent.InputError.InvalidInput;
    }

    var totals = allocator.alloc(u64, ops_list.items.len) catch return advent.InputError.InvalidInput;
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
            const value = std.fmt.parseInt(u64, item, 10) catch return advent.InputError.InvalidInput;
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

    const buf = std.fmt.allocPrint(allocator, "{d}", .{total}) catch return advent.InputError.InvalidInput;
    return buf;
}

const Op = enum { add, mul };
