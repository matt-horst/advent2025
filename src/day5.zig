const std = @import("std");
const advent = @import("root.zig");

const TreeNode = struct {
    left: ?*TreeNode,
    right: ?*TreeNode,
    low: u64,
    high: u64,

    fn create(allocator: std.mem.Allocator, low: u64, high: u64) !*@This() {
        var obj = try allocator.create(@This());

        obj.low = low;
        obj.high = high;
        obj.left = null;
        obj.right = null;

        return obj;
    }

    fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
        if (self.left) |l| l.deinit(allocator);
        if (self.right) |r| r.deinit(allocator);

        allocator.destroy(self);
    }

    fn insert(self: *@This(), allocator: std.mem.Allocator, low: u64, high: u64) !void {
        if (high < self.low) {
            // The new node should be created to the left
            if (self.left) |l| {
                return try l.insert(allocator, low, high);
            } else {
                self.left = try TreeNode.create(allocator, low, high);
                return;
            }
        } 

        if (low > self.high) {
            // The new node should be created to the right
            if (self.right) |r| {
                return try r.insert(allocator, low, high);
            } else {
                self.right = try TreeNode.create(allocator, low, high);
                return;
            }
        }

        // Otherwise the ranges overlap => merge!
        self.low = @min(self.low, low);
        self.high = @max(self.high, high);

        return;
    }

    fn find(self: *const @This(), value: u64) bool {
        if (value < self.low) {
            // The value must be to the left (or not present)
            if (self.left) |l| {
                return l.find(value);
            } else {
                return false;
            }
        }

        if (value > self.high) {
            // The value must be to the right (or not present)
            if (self.right) |r| {
                return r.find(value);
            } else {
                return false;
            }
        }

        return true;
    }
};

pub fn part1(allocator: std.mem.Allocator, input: []const u8) advent.InputError![]const u8 {
    var root: ?*TreeNode = null;
    defer if (root) |r| r.deinit(allocator);
    var count: u64 = 0;

    var it = std.mem.splitSequence(u8, input[0 .. input.len - 1], "\n\n");
    const ranges = it.first();
    const ids = it.rest();

    var ranges_it = std.mem.splitScalar(u8, ranges, '\n');
    while (ranges_it.next()) |line| {
        var range_it = std.mem.splitScalar(u8, line, '-');
        const low = std.fmt.parseInt(u64, range_it.first(), 10) catch return advent.InputError.InvalidInput;
        const high = std.fmt.parseInt(u64, range_it.rest(), 10) catch return advent.InputError.InvalidInput;

        if (root) |r| {
            r.insert(allocator, low, high) catch return advent.InputError.InvalidInput;
        } else {
            root = TreeNode.create(allocator, low, high) catch return advent.InputError.InvalidInput;
        }
    }

    var ids_it = std.mem.splitScalar(u8, ids, '\n');
    while (ids_it.next()) |line| {
        const id = std.fmt.parseInt(u64, line, 10) catch return advent.InputError.InvalidInput;

        if (root) |r| {
            if (r.find(id)) {
                count += 1;
            }
        }
    }

    const result = std.fmt.allocPrint(allocator, "{d}", .{count}) catch return advent.InputError.InvalidInput;
    return result;
}
