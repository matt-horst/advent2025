const std = @import("std");
const advent = @import("root.zig");

pub const IntervalTree = struct {
    const Node = struct {
        left: ?*Node = null,
        right: ?*Node = null,

        low: u64,
        high: u64,

        pub fn create(allocator: std.mem.Allocator, low: u64, high: u64) !*Node {
            const n = try allocator.create(Node);
            n.* = .{
                .low = low,
                .high = high,
            };
            return n;
        }

        pub fn destroy(self: *Node, allocator: std.mem.Allocator) void {
            if (self.left) |l| l.destroy(allocator);
            if (self.right) |r| r.destroy(allocator);
            allocator.destroy(self);
        }

        fn overlapsOrAdjacent(a_low: u64, a_high: u64, b_low: u64, b_high: u64) bool {
            return !(a_high < b_low - 1 or b_high < a_low - 1);
        }

        pub fn insert(self: *Node, allocator: std.mem.Allocator, low: u64, high: u64) error{OutOfMemory}!void {
            // Standard BST insert by low (break ties using high)
            if (high < self.low - 1) {
                if (self.left) |l| {
                    try l.insert(allocator, low, high);
                } else {
                    self.left = try Node.create(allocator, low, high);
                }

                return;
            } 

            if (low > self.high + 1) {
                if (self.right) |r| {
                    try r.insert(allocator, low, high);
                } else {
                    self.right = try Node.create(allocator, low, high);
                }

                return;
            }

            self.low = @min(self.low, low);
            self.high = @max(self.high, high);

            try self.mergeWithChildren(allocator);
        }

        fn mergeWithChildren(self: *Node, allocator: std.mem.Allocator) !void {
            while (self.left) |l| {
                if (Node.overlapsOrAdjacent(self.low, self.high, l.low, l.high)) {
                    const old_left = l;
                    const left_sub_left = old_left.left;
                    const left_sub_right = old_left.right;

                    self.low = @min(self.low, old_left.low);
                    self.high = @max(self.high, old_left.high);

                    self.left = null;

                    allocator.destroy(old_left);

                    if (left_sub_left) |s| try self.appendSubtreeAndFree(allocator, s);
                    if (left_sub_right) |s| try self.appendSubtreeAndFree(allocator, s);
                } else {
                    break;
                }
            }

            while (self.right) |r| {
                if (Node.overlapsOrAdjacent(self.low, self.high, r.low, r.high)) {
                    const old_right = r;
                    const right_sub_left = old_right.left;
                    const right_sub_right = old_right.right;

                    self.low = @min(self.low, old_right.low);
                    self.high = @max(self.high, old_right.high);

                    self.right = null;
                    allocator.destroy(old_right);

                    if (right_sub_left) |s| try self.appendSubtreeAndFree(allocator, s);
                    if (right_sub_right) |s| try self.appendSubtreeAndFree(allocator, s);
                } else {
                    break;
                }
            }
        }

        fn appendSubtreeAndFree(self: *Node, allocator: std.mem.Allocator, subtree: *Node) !void {
            const left = subtree.left;
            const right = subtree.right;

            subtree.left = null;
            subtree.right = null;

            try self.insert(allocator, subtree.low, subtree.high);

            allocator.destroy(subtree);

            if (left) |l| try self.appendSubtreeAndFree(allocator, l);
            if (right) |r| try self.appendSubtreeAndFree(allocator, r);
        }

        pub fn contains(self: *const Node, value: u64) bool {
            if (value < self.low) {
                if (self.left) |l| {
                    return l.contains(value);
                } 

                return false;
            }

            if (value > self.high) {
                if (self.right) |r| {
                    return r.contains(value);
                }

                return false;
            }

            return true;
        }

        pub fn sum(self: *const Node, low_limit: u64, high_limit: u64) u64 {
            const low_val = @max(self.low, low_limit);
            const high_val = @min(self.high, high_limit);

            if (low_val > high_val) {
                return 0;
            }

            var count: u64 = high_val - low_val + 1;

            if (self.left) |l| {
                count += l.sum(low_limit, low_val - 1);
            }

            if (self.right) |r| {
                count += r.sum(high_val + 1, high_limit);
            }

            return count;
        }

        pub fn print(self: *const Node, writer: anytype, depth: usize) !void {
            if (self.left) |l| try l.print(writer, depth + 1);
            try writer.splatBytesAll("  ", depth);
            try writer.print("{d}-{d}\n", .{ self.low, self.high });
            if (self.right) |r| try r.print(writer, depth + 1);
        }
    };

    root: ?*Node = null,

    pub fn insert(self: *IntervalTree, allocator: std.mem.Allocator, low: u64, high: u64) !void {
        if (self.root) |r| {
            try r.insert(allocator, low, high);
        } else {
            self.root = try Node.create(allocator, low, high);
        }
    }

    pub fn contains(self: *const IntervalTree, value: u64) bool {
        return if (self.root) |r| r.contains(value) else false;
    }

    pub fn sum(self: *const IntervalTree) u64 {
        return if (self.root) |r| r.sum(0, std.math.maxInt(u64)) else 0;
    }

    pub fn destroy(self: *IntervalTree, allocator: std.mem.Allocator) void {
        if (self.root) |r| r.destroy(allocator);
        self.root = null;
    }

    pub fn print(self: *const IntervalTree, writer: anytype) !void {
        if (self.root) |r| {
            try r.print(writer, 0);
        } else {
            try writer.print("(empty)\n", .{});
        }
    }
};

pub fn part1(allocator: std.mem.Allocator, input: []const u8) advent.InputError![]const u8 {
    var tree = IntervalTree{};
    defer tree.destroy(allocator);
    var count: u64 = 0;

    var it = std.mem.splitSequence(u8, input[0 .. input.len - 1], "\n\n");
    const ranges = it.first();
    const ids = it.rest();

    var ranges_it = std.mem.splitScalar(u8, ranges, '\n');
    while (ranges_it.next()) |line| {
        var range_it = std.mem.splitScalar(u8, line, '-');
        const low = std.fmt.parseInt(u64, range_it.first(), 10) catch return advent.InputError.InvalidInput;
        const high = std.fmt.parseInt(u64, range_it.rest(), 10) catch return advent.InputError.InvalidInput;

        tree.insert(allocator, low, high) catch return advent.InputError.InvalidInput;
    }

    var ids_it = std.mem.splitScalar(u8, ids, '\n');
    while (ids_it.next()) |line| {
        const id = std.fmt.parseInt(u64, line, 10) catch return advent.InputError.InvalidInput;

        if (tree.contains(id)) {
            count += 1;
        }
    }

    const result = std.fmt.allocPrint(allocator, "{d}", .{count}) catch return advent.InputError.InvalidInput;
    return result;
}

pub fn part2(allocator: std.mem.Allocator, input: []const u8) advent.InputError![]const u8 {
    var tree = IntervalTree{};
    defer tree.destroy(allocator);

    var it = std.mem.splitSequence(u8, input[0 .. input.len - 1], "\n\n");
    const ranges = it.first();

    var ranges_it = std.mem.splitScalar(u8, ranges, '\n');
    while (ranges_it.next()) |line| {
        var range_it = std.mem.splitScalar(u8, line, '-');
        const low = std.fmt.parseInt(u64, range_it.first(), 10) catch return advent.InputError.InvalidInput;
        const high = std.fmt.parseInt(u64, range_it.rest(), 10) catch return advent.InputError.InvalidInput;

        tree.insert(allocator, low, high) catch return advent.InputError.InvalidInput;
    }

    const count = tree.sum();

    const result = std.fmt.allocPrint(allocator, "{d}", .{count}) catch return advent.InputError.InvalidInput;
    return result;
}
