const std = @import("std");
const advent = @import("root.zig");
const AdventError = advent.AdventError;

var limit: usize = 1000;

pub fn part1(allocator: std.mem.Allocator, input: []const u8) AdventError![]const u8 {
    var total: i64 = 1;

    var boxes = std.ArrayList([3]i64){};
    defer boxes.deinit(allocator);

    var it = std.mem.tokenizeScalar(u8, input, '\n');
    while (it.next()) |line| {
        var line_it = std.mem.tokenizeScalar(u8, line, ',');
        const x = std.fmt.parseInt(i64, line_it.next() orelse return AdventError.ParseError, 10) catch return AdventError.ParseError;
        const y = std.fmt.parseInt(i64, line_it.next() orelse return AdventError.ParseError, 10) catch return AdventError.ParseError;
        const z = std.fmt.parseInt(i64, line_it.next() orelse return AdventError.ParseError, 10) catch return AdventError.ParseError;

        const pos = [3]i64{ x, y, z };
        boxes.append(allocator, pos) catch return AdventError.OutOfMemory;
    }

    const count = boxes.items.len;
    var min_max_heap = MinMaxHeap(BoxDist).create(allocator, limit, BoxDist.cmp) catch return AdventError.OutOfMemory;
    defer min_max_heap.deinit(allocator);

    for (0..count) |i| {
        for (i + 1..count) |j| {
            const a = boxes.items[i];
            const b = boxes.items[j];

            const dist = distance(a, b);

            const box = BoxDist{ .a = i, .b = j, .dist = dist };

            if (min_max_heap.len < min_max_heap.cap) {
                try min_max_heap.insert(box);
            } else {
                const max = min_max_heap.peekMax();
                if (max) |m| {
                    if (dist < m.dist) {
                        _ = min_max_heap.extractMax();
                        try min_max_heap.insert(box);
                    }
                } else {
                    try min_max_heap.insert(box);
                }
            }
        }
    }

    var ds = DisjointSet{};
    defer ds.deinit(allocator);
    var set_ids = std.AutoHashMap(usize, usize).init(allocator);
    defer set_ids.deinit();
    while (min_max_heap.extractMin()) |min| {
        var a_id = set_ids.get(min.a);
        if (a_id == null) {
            const id = ds.makeSet(allocator) catch return AdventError.OutOfMemory;
            set_ids.put(min.a, id) catch return AdventError.OutOfMemory;
            a_id = id;
        }

        var b_id = set_ids.get(min.b);
        if (b_id == null) {
            const id = ds.makeSet(allocator) catch return AdventError.OutOfMemory;
            set_ids.put(min.b, id) catch return AdventError.OutOfMemory;
            b_id = id;
        }

        ds.merge(a_id.?, b_id.?) catch return AdventError.ParseError;
    }

    var seen = std.AutoHashMap(usize, void).init(allocator);
    defer seen.deinit();

    var size_min_max = MinMaxHeap(i64).create(allocator, 3, size_cmp) catch return AdventError.OutOfMemory;
    defer size_min_max.deinit(allocator);

    for (0.., ds.nodes.items) |i, _| {
        const root = ds.find(i).?;

        if (seen.contains(root)) continue;
        seen.put(root, {}) catch return AdventError.OutOfMemory;

        const size: i64 = @intCast(ds.nodes.items[root].size);

        if (size_min_max.len == size_min_max.cap) {
            const min = size_min_max.peekMin().?;
            if (size > min) {
                _ = size_min_max.extractMin();
                size_min_max.insert(size) catch return AdventError.ParseError;
            }
        } else {
            size_min_max.insert(size) catch return AdventError.ParseError;
        }
    }

    while (size_min_max.extractMax()) |max| {
        total *= max;
    }

    const buf = std.fmt.allocPrint(allocator, "{d}", .{total}) catch return AdventError.OutOfMemory;
    return buf;
}

pub fn part2(allocator: std.mem.Allocator, input: []const u8) AdventError![]const u8 {
    var boxes = std.ArrayList([3]i64){};
    defer boxes.deinit(allocator);

    var it = std.mem.tokenizeScalar(u8, input, '\n');
    while (it.next()) |line| {
        var line_it = std.mem.tokenizeScalar(u8, line, ',');
        const x = std.fmt.parseInt(i64, line_it.next() orelse return AdventError.ParseError, 10) catch return AdventError.ParseError;
        const y = std.fmt.parseInt(i64, line_it.next() orelse return AdventError.ParseError, 10) catch return AdventError.ParseError;
        const z = std.fmt.parseInt(i64, line_it.next() orelse return AdventError.ParseError, 10) catch return AdventError.ParseError;

        const pos = [3]i64{ x, y, z };
        boxes.append(allocator, pos) catch return AdventError.OutOfMemory;
    }

    const count = boxes.items.len;
    var dists = std.ArrayList(BoxDist){};
    defer dists.deinit(allocator);

    for (0..count) |i| {
        for (i + 1..count) |j| {
            const a = boxes.items[i];
            const b = boxes.items[j];

            const dist = distance(a, b);

            const box = BoxDist{ .a = i, .b = j, .dist = dist };

            dists.append(allocator, box) catch return AdventError.OutOfMemory;
        }
    }

    const lt = struct {
        fn cmp(_: void, a: BoxDist, b: BoxDist) bool {
            return a.dist < b.dist;
        }
    }.cmp;

    std.mem.sort(BoxDist, dists.items, {}, lt);

    var ds = DisjointSet{};
    defer ds.deinit(allocator);
    var set_ids = std.AutoHashMap(usize, usize).init(allocator);
    defer set_ids.deinit();

    var final: ?BoxDist = null;
    for (dists.items) |min| {
        var a_id = set_ids.get(min.a);
        if (a_id == null) {
            const id = ds.makeSet(allocator) catch return AdventError.OutOfMemory;
            set_ids.put(min.a, id) catch return AdventError.OutOfMemory;
            a_id = id;
        }

        var b_id = set_ids.get(min.b);
        if (b_id == null) {
            const id = ds.makeSet(allocator) catch return AdventError.OutOfMemory;
            set_ids.put(min.b, id) catch return AdventError.OutOfMemory;
            b_id = id;
        }

        ds.merge(a_id.?, b_id.?) catch return AdventError.ParseError;

        const root = ds.find(0).?;
        if (ds.nodes.items[root].size == boxes.items.len) {
            std.debug.print("found: {any}\n", .{min});
            final = min;
            break;
        }
    }

    if (final) |f| {
        std.debug.print("final: {any}\n", .{f});
        const value = boxes.items[f.a][0] * boxes.items[f.b][0];
        const buf = std.fmt.allocPrint(allocator, "{d}", .{value}) catch return AdventError.OutOfMemory;
        return buf;
    }

    return AdventError.ParseError;

}

fn size_cmp(a: i64, b: i64) Cmp {
    if (a < b) return .lt;
    if (a > b) return .gt;
    return .eq;
}

const BoxDist = struct {
    a: usize,
    b: usize,
    dist: i64,

    const Self = @This();

    fn cmp(self: Self, other: Self) Cmp {
        if (self.dist > other.dist) return .gt;
        if (self.dist < other.dist) return .lt;

        return .eq;
    }

    pub fn format(self: Self, writer: anytype, _: std.fmt.FormatOptions) !void {
        try writer.print("({}) -> ({}) = {}", .{ self.a, self.b, self.dist });
    }
};

fn distance(a: [3]i64, b: [3]i64) i64 {
    var total: i64 = 0;
    for (0..3) |i| {
        const diff = a[i] - b[i];
        total += diff * diff;
    }
    return total;
}

const Cmp = enum { lt, eq, gt };

fn MinMaxHeap(comptime T: type) type {
    const CmpFn = fn (T, T) Cmp;
    return struct {
        items: []T,
        len: usize = 0,
        cap: usize,
        cmp: *const CmpFn,

        const Self = @This();

        pub fn create(allocator: std.mem.Allocator, n: usize, cmp: *const CmpFn) !Self {
            const items = try allocator.alloc(T, n);
            return .{ .items = items, .cap = n, .cmp = cmp };
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
            const i: usize = switch (self.len) {
                0 => return null,
                1 => 0,
                2 => 1,
                else => if (self.cmp(self.items[1], self.items[2]) == .gt) 1 else 2,
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
                else => return if (self.cmp(self.items[1], self.items[2]) == .gt) self.items[1] else self.items[2],
            }
        }

        pub fn peekMin(self: *Self) ?T {
            if (self.len == 0) return null;

            return self.items[0];
        }

        fn pushDown(self: *Self, i: usize) void {
            if (level(i) % 2 == 0) {
                self.pushDownMin(i);
            } else {
                self.pushDownMax(i);
            }
        }

        fn pushDownMin(self: *Self, i: usize) void {
            const min = self.findMinChildOrGrandchild(i);
            if (min) |m| {
                if (m > 2 * i + 2) {
                    if (self.cmp(self.items[m], self.items[i]) == .lt) {
                        std.mem.swap(T, &self.items[i], &self.items[m]);
                        const p = (m - 1) / 2;
                        // if (self.items[m] > self.items[p]) {
                        if (self.cmp(self.items[m], self.items[p]) == .gt) {
                            std.mem.swap(T, &self.items[m], &self.items[p]);
                        }
                        self.pushDown(m);
                    }
                    // } else if (self.items[m] < self.items[i]) {
                } else if (self.cmp(self.items[m], self.items[i]) == .lt) {
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
                    // if (self.items[c] < self.items[m]) {
                    if (self.cmp(self.items[c], self.items[m]) == .lt) {
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
                    // if (self.items[gc] < self.items[m]) {
                    if (self.cmp(self.items[gc], self.items[m]) == .lt) {
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
                    // if (self.items[c] > self.items[m]) {
                    if (self.cmp(self.items[c], self.items[m]) == .gt) {
                        max = c;
                    }
                } else {
                    max = c;
                }
            }

            for (3..7) |j| {
                const gc = 4 * i + j;
                if (gc >= self.len) break;

                if (max) |m| {
                    // if (self.items[gc] < self.items[m]) {
                    if (self.cmp(self.items[gc], self.items[m]) == .gt) {
                        max = gc;
                    }
                } else {
                    max = gc;
                }
            }

            return max;
        }

        fn pushDownMax(self: *Self, i: usize) void {
            const max = self.findMaxChildOrGrandchild(i);
            if (max) |m| {
                if (m > 2 * i + 2) {
                    // if (self.items[m] > self.items[i]) {
                    if (self.cmp(self.items[m], self.items[i]) == .gt) {
                        std.mem.swap(T, &self.items[i], &self.items[m]);
                        const p = (m - 1) / 2;
                        // if (self.items[m] < self.items[p]) {
                        if (self.cmp(self.items[m], self.items[p]) == .lt) {
                            std.mem.swap(T, &self.items[m], &self.items[p]);
                        }
                        self.pushDown(m);
                    }
                    // } else if (self.items[m] > self.items[i]) {
                } else if (self.cmp(self.items[m], self.items[i]) == .gt) {
                    std.mem.swap(T, &self.items[i], &self.items[m]);
                }
            }
        }

        fn level(i: usize) usize {
            var v = i + 1;
            var lvl: usize = 0;
            while (v > 1) : (v >>= 1) {
                lvl += 1;
            }
            return lvl;
        }

        fn pushUp(self: *Self, i: usize) void {
            if (i == 0) return;

            const p = (i - 1) / 2;
            if (level(i) % 2 == 0) {
                // if (self.items[i] > self.items[p]) {
                if (self.cmp(self.items[i], self.items[p]) == .gt) {
                    std.mem.swap(T, &self.items[i], &self.items[p]);
                    self.pushUpMax(p);
                } else {
                    self.pushUpMin(i);
                }
            } else {
                // if (self.items[i] < self.items[p]) {
                if (self.cmp(self.items[i], self.items[p]) == .lt) {
                    std.mem.swap(T, &self.items[i], &self.items[p]);
                    self.pushUpMin(p);
                } else {
                    self.pushUpMax(i);
                }
            }
        }

        fn pushUpMin(self: *Self, i: usize) void {
            if (i == 0) return;
            if (i == 0) return;

            const p = (i - 1) / 2;
            if (p == 0) {
                return;
            }
            const gp = (p - 1) / 2;
            // if (p > 0 and self.items[i] < self.items[gp]) {
            if (self.cmp(self.items[i], self.items[gp]) == .lt) {
                std.mem.swap(T, &self.items[i], &self.items[gp]);
                self.pushUpMin(gp);
            }
        }

        fn pushUpMax(self: *Self, i: usize) void {
            if (i == 0) return;
            const p = (i - 1) / 2;
            if (p == 0) {
                return;
            }
            const gp = (p - 1) / 2;
            // if (p > 0 and self.items[i] > self.items[gp]) {
            if (self.cmp(self.items[i], self.items[gp]) == .gt) {
                std.mem.swap(T, &self.items[i], &self.items[gp]);
                self.pushUpMax(gp);
            }
        }
    };
}

const DisjointSet = struct {
    nodes: std.ArrayList(Node) = std.ArrayList(Node).empty,

    const Self = @This();

    pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
        self.nodes.deinit(allocator);
    }

    pub fn find(self: *Self, id: usize) ?usize {
        if (id < self.nodes.items.len) {
            var n = self.nodes.items[id];
            if (n.parent) |p| {
                n.parent = self.find(p).?;
                return n.parent;
            }

            return id;
        }

        return null;
    }

    pub fn merge(self: *Self, a: usize, b: usize) !void {
        const a_root = self.find(a) orelse return error.InvalidID;
        const b_root = self.find(b) orelse return error.InvalidID;

        if (a_root == b_root) return;

        var a_node = &self.nodes.items[a_root];
        var b_node = &self.nodes.items[b_root];
        if (a_node.size < b_node.size) {
            a_node.parent = b_root;
            b_node.size += a_node.size;
        } else {
            b_node.parent = a_root;
            a_node.size += b_node.size;
        }
    }

    pub fn makeSet(self: *Self, allocator: std.mem.Allocator) !usize {
        const node: Node = .{};
        try self.nodes.append(allocator, node);
        return self.nodes.items.len - 1;
    }

    const Node = struct {
        parent: ?usize = null,
        size: usize = 1,
    };
};

test "test day 8 part 1" {
    const gpa = std.testing.allocator;

    limit = 10;

    const result = try advent.process_file(gpa, part1, "input/example_day8");
    defer gpa.free(result);

    try std.testing.expectEqualStrings("40", result);
}

test "test day 8 part 2" {
    const gpa = std.testing.allocator;

    const result = try advent.process_file(gpa, part2, "input/example_day8");
    defer gpa.free(result);

    try std.testing.expectEqualStrings("25272", result);
}
