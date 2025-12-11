const std = @import("std");
const advent = @import("root.zig");
const AdventError = advent.AdventError;

pub fn part1(allocator: std.mem.Allocator, input: []const u8) AdventError![]const u8 {
    const total: u64 = 0;
    _ = input;

    // var it = std.mem.tokenizeScalar(u8, input, '\n');
    // main: while (it.next()) |line| {
    //     const cfg = try MachineConfig.parse(allocator, line);
    //     defer cfg.deinit(allocator);
    //
    //     var seen = std.AutoHashMap(u64, void).init(allocator);
    //     defer seen.deinit();
    //
    //     var queue = Queue(struct { id: u64, depth: u64 }).init(allocator);
    //     defer queue.deinit();
    //     queue.pushRight(.{ .id = 0, .depth = 0 }) catch return AdventError.OutOfMemory;
    //
    //     while (queue.popLeft()) |node| {
    //         if (seen.get(node.id) != null) continue;
    //
    //         seen.put(node.id, {}) catch return AdventError.OutOfMemory;
    //
    //         for (cfg.buttons) |btn| {
    //             const adj = toggle(node.id, btn);
    //             queue.pushRight(.{ .id = adj, .depth = node.depth + 1 }) catch return AdventError.OutOfMemory;
    //
    //             if (adj == cfg.lights) {
    //                 total += node.depth + 1;
    //                 continue :main;
    //             }
    //         }
    //     }
    // }

    const buf = std.fmt.allocPrint(allocator, "{}", .{total});
    return buf;
}

pub fn part2(allocator: std.mem.Allocator, input: []const u8) AdventError![]const u8 {
    const total: u64 = 0;
    var it = std.mem.tokenizeScalar(u8, input, '\n');
    while (it.next()) |line| {
        const cfg = try MachineConfig.parse(allocator, line);
        defer cfg.deinit(allocator);

        const factors = try calcFactors(allocator, cfg.jolts);
        defer allocator.free(factors);

        const coins = try convertToCoins(allocator, factors, cfg.buttons);
        defer allocator.free(coins);

        const target = convertToTarget(factors, cfg.jolts);

        std.debug.print("factors: {any}, coins: {any}, target: {}\n", .{factors, coins, target});
        // const ans = try makeChange(allocator, coins, target);
        // std.debug.print("{}\n", .{ans});
        // total += @intCast(ans);
    }

    const buf = std.fmt.allocPrint(allocator, "{}", .{total});
    return buf;
}

fn makeChange(allocator: std.mem.Allocator, coins: []u64, target: u64) !u64 {
    var dp = allocator.alloc(u64, target + 1) catch return AdventError.OutOfMemory;
    defer allocator.free(dp);
    @memset(dp, std.math.maxInt(u64) - 1);

    dp[0] = 0;

    for (1..@intCast(target + 1)) |i| {
        for (coins) |coin| {
            if (i >= coin) {
                dp[i] = @min(dp[i], 1 + dp[i - coin]);
            }
        }
    }

    return if (dp[target] >= std.math.maxInt(u64) - 1) AdventError.ParseError else dp[target];
}

fn parseLights(input: []const u8) ![]u64 {
    var lights: u64 = 0;
    const one: u64 = 1;

    for (0.., input) |i, c| {
        switch (c) {
            '.' => {},
            '#' => lights |= one << @intCast(i),
            else => return AdventError.ParseError,
        }
    }

    return lights;
}

fn parseArray(comptime T: type, allocator: std.mem.Allocator, input: []const u8) ![]T {
    var lst = std.ArrayList(T){};
    defer lst.deinit(allocator);

    var it = std.mem.tokenizeScalar(u8, input, ',');
    while (it.next()) |item| {
        const v = std.fmt.parseInt(T, item, 10) catch return AdventError.ParseError;
        lst.append(allocator, v) catch return AdventError.OutOfMemory;
    }

    const jolts = allocator.alloc(T, lst.items.len) catch return AdventError.OutOfMemory;
    @memcpy(jolts, lst.items);

    return jolts;
}

const MachineConfig = struct {
    lights: []bool,
    buttons: [][]u64,
    jolts: []u64,

    const Self = @This();

    pub fn parse(allocator: std.mem.Allocator, input: []const u8) !Self {
        const lights: []bool = undefined;
        var buttons_list = std.ArrayList([]usize){};
        defer buttons_list.deinit(allocator);
        var jolts: []u64 = undefined;

        var it = std.mem.tokenizeScalar(u8, input, ' ');
        while (it.next()) |item| {
            const first = item[0];
            const middle = item[1 .. item.len - 1];
            const last = item[item.len - 1];
            if (first == '[' and last == ']') {
                // lights = try parseLights(middle);
            } else if (first == '(' and last == ')') {
                const button = try parseArray(usize, allocator, middle);
                buttons_list.append(allocator, button) catch return AdventError.OutOfMemory;
            } else if (first == '{' and last == '}') {
                jolts = try parseArray(u64, allocator, middle);
            } else {
                return AdventError.ParseError;
            }
        }

        const buttons = allocator.alloc([]usize, buttons_list.items.len) catch return AdventError.OutOfMemory;
        @memcpy(buttons, buttons_list.items);

        return .{ .lights = lights, .buttons = buttons, .jolts = jolts };
    }

    pub fn deinit(self: Self, allocator: std.mem.Allocator) void {
        for (self.buttons) |button| {
            allocator.free(button);
        }
        allocator.free(self.buttons);
        allocator.free(self.jolts);
    }
};

fn calcFactors(allocator: std.mem.Allocator, jolts: []u64) ![]const u64 {
    var factors = allocator.alloc(u64, jolts.len) catch return AdventError.OutOfMemory;
    factors[0] = 1;

    for (1..jolts.len) |i| {
        factors[i] = factors[i - 1] * (jolts[i - 1] + 1);
    }

    return factors;
}

fn convertToTarget(factors: []const u64, vs: []u64) u64 {
    var total: u64 = 0;

    for (factors, vs) |f, v| {
        total += f * v;
    }

    return total;
}

fn convertToCoins(allocator: std.mem.Allocator, factors: []const u64, buttons: [][]usize) ![]u64 {
    var buf = allocator.alloc(u64, buttons.len) catch return AdventError.OutOfMemory;

    for (0.., buttons) |i, button| {
        var v: u64 = 0;
        for (button) |k| {
            v += factors[k];
        }
        buf[i] = v;
    }

    return buf;
}

// test "day 10 part 1" {
//     const gpa = std.testing.allocator;
//
//     const result = try advent.process_file(gpa, part1, "input/example_day10");
//     defer gpa.free(result);
//
//     try std.testing.expectEqualStrings("7", result);
// }

test "day 10 part 2" {
    const gpa = std.testing.allocator;

    const result = try advent.process_file(gpa, part2, "input/example_day10");
    defer gpa.free(result);

    try std.testing.expectEqualStrings("33", result);
}
