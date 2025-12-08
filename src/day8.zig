const std = @import("std");
const advent = @import("root.zig");
const AdventError = advent.AdventError;

pub fn part1(allocator: std.mem.Allocator, input: []const u8) AdventError![]const u8 {
    const total: i32 = 0;

    var boxes = std.ArrayList([3]i32){};
    defer boxes.deinit(allocator);

    var it = std.mem.tokenizeScalar(u8, input, '\n');
    while (it.next()) |line| {
        var line_it = std.mem.tokenizeScalar(u8, line, ',');
        const x = std.fmt.parseInt(i32, line_it.next() orelse return AdventError.ParseError, 10) catch return AdventError.ParseError;
        const y = std.fmt.parseInt(i32, line_it.next() orelse return AdventError.ParseError, 10) catch return AdventError.ParseError;
        const z = std.fmt.parseInt(i32, line_it.next() orelse return AdventError.ParseError, 10) catch return AdventError.ParseError;

        const pos = [3]i32{ x, y, z };
        boxes.append(allocator, pos) catch return AdventError.OutOfMemory;
    }

    const count = boxes.items.len;
    const limit = 10;
    var min_max_heap = MinMaxHeap(i32).create(allocator, limit) catch return AdventError.OutOfMemory;

    for (0..count) |i| {
        for (i + 1..count) |j| {
            const a = boxes.items[i];
            const b = boxes.items[j];

            const dist = distance(a, b);

            std.debug.print("({}, {}, {}) -> ({}, {}, {}) = {}\n", .{ a[0], a[1], a[2], b[0], b[1], b[2], dist });

            if (min_max_heap.len < min_max_heap.cap) {
                std.debug.print("inserting\n", .{});
                try min_max_heap.insert(dist);
            } else {
                const max = min_max_heap.peekMax();
                if (max) |m| {
                    if (dist < m) {
                        std.debug.print("inserting\n", .{});
                        _ = min_max_heap.extractMax();
                        try min_max_heap.insert(dist);
                    }
                } else {
                    std.debug.print("skipping\n", .{});
                    try min_max_heap.insert(dist);
                }
            }
        }
    }

    while (min_max_heap.extractMin()) |min| {
        std.debug.print("extracting: {}\n", .{min});
    }

    const buf = std.fmt.allocPrint(allocator, "{d}", .{total}) catch return AdventError.OutOfMemory;
    return buf;
}

fn distance(a: [3]i32, b: [3]i32) i32 {
    var total: i32 = 0;
    for (0..3) |i| {
        const diff = a[i] - b[i];
        total += diff * diff;
    }
    return total;
}

fn MinMaxHeap(comptime T: type) type {
    return struct {
        items: []T,
        len: usize = 0,
        cap: usize,

        const Self = @This();

        pub fn create(allocator: std.mem.Allocator, n: usize) !Self {
            const items = try allocator.alloc(T, n);
            return .{ .items = items, .cap = n };
        }

        pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
            allocator.free(self.items);
        }

        pub fn insert(self: *Self, item: T) !void {
            if (self.len == self.cap) return AdventError.OutOfMemory;

            self.items[self.len] = item;
            self.len += 1;

            self.pushUp(self.len - 1);
        }

        pub fn extractMin(self: *Self) ?T {
            if (self.len == 0) return null;

            const v = self.items[0];
            self.items[0] = self.items[self.len - 1];
            self.len -= 1;

            self.pushDown(0);

            return v;
        }

        pub fn extractMax(self: *Self) ?T {
            const i = switch (self.len) {
                0 => return null,
                1 => 0,
                2 => 1,
                else => std.mem.indexOfMax(T, self.items[1..3]),
            };

            const v = self.items[i];
            self.items[i] = self.items[self.len - 1];
            self.len -= 1;

            self.pushDown(i);

            return v;
        }

        pub fn peekMax(self: *Self) ?T {
            switch (self.len) {
                0 => return null,
                1 => return self.items[0],
                2 => return self.items[1],
                else => return std.mem.max(T, self.items[1..3]),
            }
        }

        fn pushDown(self: *Self, i: usize) void {
            const level: usize = @intFromFloat(@floor(@log2(@as(f64, @floatFromInt(i + 1)))));
            if (level % 2 == 0) {
                self.pushDownMin(i);
            } else {
                self.pushDownMax(i);
            }
        }

        fn pushDownMin(self: *Self, i: usize) void {
            const min = self.findMinChildOrGrandchild(i);
            if (min) |m| {
                if (m > 2 * i + 2) {
                    if (self.items[m] < self.items[i]) {
                        std.mem.swap(T, &self.items[i], &self.items[m]);
                        const p = (m - 1) / 2;
                        if (self.items[m] > self.items[p]) {
                            std.mem.swap(T, &self.items[m], &self.items[p]);
                        }
                        self.pushDown(m);
                    }
                } else if (self.items[m] < self.items[i]) {
                    std.mem.swap(T, &self.items[i], &self.items[m]);
                }
            }
        }

        fn findMinChildOrGrandchild(self: *Self, i: usize) ?usize {
            var min: ?usize = null;
            for (1..3) |j| {
                const c = 2 * i + j;
                if (c >= self.len) break;

                if (min) |m| {
                    if (self.items[c] < self.items[m]) {
                        min = c;
                    }
                } else {
                    min = c;
                }
            }

            for (3..7) |j| {
                const gc = 4 * i + j;
                if (gc >= self.len) break;

                if (min) |m| {
                    if (self.items[gc] < self.items[m]) {
                        min = gc;
                    }
                } else {
                    min = gc;
                }
            }

            return min;
        }

        fn findMaxChildOrGrandchild(self: *Self, i: usize) ?usize {
            var max: ?usize = null;
            for (1..3) |j| {
                const c = 2 * i + j;
                if (c >= self.len) break;

                if (max) |m| {
                    if (self.items[c] > self.items[m]) {
                        max = c;
                    }
                } else {
                    max = c;
                }

                for (1..3) |k| {
                    const gc = 2 * c + k;
                    if (gc >= self.len) break;

                    if (max) |m| {
                        if (self.items[gc] > self.items[m]) {
                            max = gc;
                        }
                    } else {
                        max = gc;
                    }
                }
            }

            return max;
        }

        fn pushDownMax(self: *Self, i: usize) void {
            const max = self.findMaxChildOrGrandchild(i);
            if (max) |m| {
                if (m > 2 * i + 2) {
                    if (self.items[m] > self.items[i]) {
                        std.mem.swap(T, &self.items[i], &self.items[m]);
                        const p = (m - 1) / 2;
                        if (self.items[m] < self.items[p]) {
                            std.mem.swap(T, &self.items[m], &self.items[p]);
                        }
                        self.pushDown(m);
                    }
                } else if (self.items[m] > self.items[i]) {
                    std.mem.swap(T, &self.items[i], &self.items[m]);
                }
            }
        }

        fn pushUp(self: *Self, i: usize) void {
            if (i == 0) return;

            const level: usize = @intFromFloat(@floor(@log2(@as(f64, @floatFromInt(i + 1)))));
            const p = (i - 1) / 2;
            if (level % 2 == 0) {
                if (self.items[i] > self.items[p]) {
                    std.mem.swap(T, &self.items[i], &self.items[p]);
                    self.pushUpMax(p);
                } else {
                    self.pushUpMin(i);
                }
            } else {
                if (self.items[i] < self.items[p]) {
                    std.mem.swap(T, &self.items[i], &self.items[p]);
                    self.pushUpMin(p);
                } else {
                    self.pushUpMax(i);
                }
            }
        }

        fn pushUpMin(self: *Self, i: usize) void {
            if (i == 0) return;

            const p = (i - 1) / 2;
            const gp = (i - 1) / 4;
            if (p > 0 and self.items[i] < self.items[gp]) {
                std.mem.swap(T, &self.items[i], &self.items[gp]);
                self.pushUpMin(gp);
            }
        }

        fn pushUpMax(self: *Self, i: usize) void {
            if (i == 0) return;
            const p = (i - 1) / 2;
            const gp = (i - 1) / 4;
            if (p > 0 and self.items[i] > self.items[gp]) {
                std.mem.swap(T, &self.items[i], &self.items[gp]);
                self.pushUpMax(gp);
            }
        }
    };
}

test "test day 8 part 1" {
    const gpa = std.testing.allocator;

    const result = try advent.process_file(gpa, part1, "input/example_day8");
    defer gpa.free(result);

    try std.testing.expectEqualStrings("40", result);
}
