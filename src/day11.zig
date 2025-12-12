const std = @import("std");
const advent = @import("root.zig");
const AdventError = advent.AdventError;

pub fn part1(allocator: std.mem.Allocator, input: []const u8) AdventError![]const u8 {
    var graph = try parse_input(allocator, input);
    defer graph.deinit();

    const total = try graph.count_paths("you", "out");

    const buf = std.fmt.allocPrint(allocator, "{}", .{total}) catch return AdventError.OutOfMemory;
    return buf;
}

fn parse_input(allocator: std.mem.Allocator, input: []const u8) !Graph {
    var graph = Graph.init(allocator);

    var it = std.mem.tokenizeScalar(u8, input, '\n');
    while (it.next()) |line| {
        try graph.parse_line(line);
    }

    return graph;
}

const Graph = struct {
    adj_list_fwd: std.StringHashMap(std.StringHashMap(void)),
    adj_list_back: std.StringHashMap(std.StringHashMap(void)),
    allocator: std.mem.Allocator,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Self {
        const adj_list_fwd = std.StringHashMap(std.StringHashMap(void)).init(allocator);
        const adj_list_back = std.StringHashMap(std.StringHashMap(void)).init(allocator);
        return .{ .adj_list_fwd = adj_list_fwd, .adj_list_back = adj_list_back, .allocator = allocator };
    }

    pub fn deinit(self: *Self) void {
        var it_fwd = self.adj_list_fwd.iterator();
        while (it_fwd.next()) |kvp| {
            kvp.value_ptr.deinit();
        }

        var it_back = self.adj_list_back.iterator();
        while (it_back.next()) |kvp| {
            kvp.value_ptr.deinit();
        }

        self.adj_list_fwd.deinit();
        self.adj_list_back.deinit();
    }

    pub fn parse_line(self: *Self, input: []const u8) !void {
        var it = std.mem.splitScalar(u8, input, ':');

        const parent = it.first();
        std.debug.assert(parent.len == 3);

        var children_list = std.StringHashMap(void).init(self.allocator);
        self.adj_list_fwd.put(parent, children_list) catch return AdventError.OutOfMemory;

        const children = it.rest();

        var it_children = std.mem.tokenizeScalar(u8, children, ' ');
        while (it_children.next()) |child| {
            std.debug.assert(child.len == 3);

            children_list.put(child, {}) catch return AdventError.OutOfMemory;

            const back = self.adj_list_back.getOrPut(child) catch return AdventError.OutOfMemory;
            if (!back.found_existing) {
                back.value_ptr.* = std.StringHashMap(void).init(self.allocator);
            }
            back.value_ptr.put(parent, {}) catch return AdventError.OutOfMemory;
        }
    }

    pub fn count_paths(self: *Self, src: []const u8, dest: []const u8) !u32 {
        var count = std.StringHashMap(u32).init(self.allocator);
        defer count.deinit();

        var stack = Stack(struct { node: []const u8, seen: bool = false }).init(self.allocator);
        defer stack.deinit();

        try stack.push(.{ .node = dest });

        while (stack.pop()) |curr| {
            if (count.get(curr.node) != null) continue;
            if (curr.seen) {
                var total: u32 = 0;

                if (std.mem.eql(u8, curr.node, src)) {
                    total = 1;
                } else if (self.adj_list_back.get(curr.node)) |adj_list| {
                    var it = adj_list.keyIterator();
                    while (it.next()) |next| {
                        total += count.get(next.*) orelse 0;
                    }
                }

                count.put(curr.node, total) catch return AdventError.OutOfMemory;
            } else {
                try stack.push(.{ .node = curr.node, .seen = true });

                if (self.adj_list_back.get(curr.node)) |adj_list| {
                    var it = adj_list.keyIterator();
                    while (it.next()) |next| {
                        try stack.push(.{ .node = next.* });
                    }
                }
            }
        }

        return if (count.get(dest)) |ans| ans else 0;
    }
};

fn Stack(comptime T: type) type {
    return struct {
        items: std.ArrayList(T) = .{},
        allocator: std.mem.Allocator,

        const Self = @This();

        pub fn init(allocator: std.mem.Allocator) Self {
            return .{ .allocator = allocator };
        }

        pub fn deinit(self: *Self) void {
            self.items.deinit(self.allocator);
        }

        pub fn push(self: *Self, item: T) !void {
            self.items.append(self.allocator, item) catch return AdventError.OutOfMemory;
        }

        pub fn pop(self: *Self) ?T {
            return self.items.pop();
        }

        pub fn isEmpty(self: *Self) bool {
            return self.items.items.len == 0;
        }
    };
}

test "day 11 part 1" {
    const gpa = std.testing.allocator;

    const result = try advent.process_file(gpa, part1, "input/example_day11");
    defer gpa.free(result);

    try std.testing.expectEqualStrings("5", result);
}
