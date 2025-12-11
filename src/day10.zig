const std = @import("std");
const advent = @import("root.zig");
const AdventError = advent.AdventError;

pub fn part1(allocator: std.mem.Allocator, input: []const u8) AdventError![]const u8 {
    var total: u32 = 0;

    var it = std.mem.tokenizeScalar(u8, input, '\n');
    main: while (it.next()) |line| {
        const cfg = try MachineConfig.parse(allocator, line);
        defer cfg.deinit(allocator);
        std.debug.print("{any}\n", .{cfg});

        var seen = std.AutoHashMap(u32, void).init(allocator);
        defer seen.deinit();

        // var adj_list = std.AutoHashMap(u32, std.AutoHashMap(u32, void)).init(allocator);
        // defer {
        //     var adj_list_it = adj_list.valueIterator();
        //     while (adj_list_it.next()) |lst| {
        //         lst.deinit();
        //     }
        //     adj_list.deinit();
        // }

        var queue = Queue(struct { id: u32, depth: u32 }).init(allocator);
        defer queue.deinit();
        queue.pushRight(.{ .id = 0, .depth = 0 }) catch return AdventError.OutOfMemory;

        while (queue.popLeft()) |node| {
            if (seen.get(node.id) != null) continue;

            seen.put(node.id, {}) catch return AdventError.OutOfMemory;

            for (cfg.buttons) |btn| {
                const adj = toggle(node.id, btn);
                queue.pushRight(.{ .id = adj, .depth = node.depth + 1 }) catch return AdventError.OutOfMemory;

                if (adj == cfg.lights) {
                    std.debug.print("found {b:06} in {}\n", .{ adj, node.depth + 1 });
                    total += node.depth + 1;
                    continue :main;
                }

                // queue.print();
                //

                // if (adj_list.getPtr(node)) |lst| {
                //     lst.put(adj, {}) catch return AdventError.OutOfMemory;
                // } else {
                //     var lst = std.AutoHashMap(u32, void).init(allocator);
                //     lst.put(adj, {}) catch return AdventError.OutOfMemory;
                //     adj_list.put(node, lst) catch return AdventError.OutOfMemory;
                // }
                //
                // if (adj_list.getPtr(adj)) |lst| {
                //     lst.put(node, {}) catch return AdventError.OutOfMemory;
                // } else {
                //     var lst = std.AutoHashMap(u32, void).init(allocator);
                //     lst.put(node, {}) catch return AdventError.OutOfMemory;
                //     adj_list.put(adj, lst) catch return AdventError.OutOfMemory;
                // }
            }
        }

        // var adj_list_it = adj_list.iterator();
        // while (adj_list_it.next()) |kvp| {
        //     std.debug.print("{}: ", .{kvp.key_ptr.*});
        //     var v_it = kvp.value_ptr.keyIterator();
        //     while (v_it.next()) |v| {
        //         std.debug.print("{}, ", .{v.*});
        //     }
        //     std.debug.print("\n", .{});
        // }
    }

    const buf = std.fmt.allocPrint(allocator, "{}", .{total});
    return buf;
}

fn Queue(comptime T: type) type {
    return struct {
        first: ?*Node = null,
        last: ?*Node = null,
        allocator: std.mem.Allocator,

        const Self = @This();

        pub fn popRight(self: *Self) ?T {
            if (self.last) |last| {
                if (last.prev) |prev| prev.next = null;
                if (self.first == self.last) {
                    self.first = null;
                }
                self.last = last.prev;

                const v = last.payload;

                self.allocator.destroy(last);

                return v;
            }

            return null;
        }

        pub fn popLeft(self: *Self) ?T {
            if (self.first) |first| {
                if (first.next) |next| next.prev = null;
                if (self.first == self.last) {
                    self.last = null;
                }
                self.first = first.next;

                const v = first.payload;

                self.allocator.destroy(first);

                return v;
            }

            return null;
        }

        pub fn pushLeft(self: *Self, v: T) !void {
            const node = try Node.create(self.allocator, v, null, self.first);

            if (self.first) |first| first.next = node;

            self.first = node;
            if (self.last == null) self.last = node;
        }

        pub fn pushRight(self: *Self, v: T) !void {
            const node = try Node.create(self.allocator, v, self.last, null);

            if (self.last) |last| last.next = node;

            if (self.first == null) self.first = node;
            self.last = node;
        }

        pub fn isEmpty(self: *Self) bool {
            return self.first == null;
        }

        pub fn init(allocator: std.mem.Allocator) Self {
            return .{ .allocator = allocator };
        }

        pub fn deinit(self: *Self) void {
            while (self.popLeft()) |_| {}
        }

        pub fn print(self: *Self) void {
            var node: ?*Node = self.first;
            while (node) |n| {
                std.debug.print("{}, ", .{n.payload});
                node = n.next;
            }

            std.debug.print("\n", .{});
        }

        const Node = struct {
            payload: T,
            next: ?*Node,
            prev: ?*Node,

            pub fn create(allocator: std.mem.Allocator, payload: T, prev: ?*Node, next: ?*Node) !*Node {
                const node = try allocator.create(Node);
                node.* = .{
                    .payload = payload,
                    .prev = prev,
                    .next = next,
                };
                return node;
            }
        };
    };
}

fn MinHeap(comptime T: type) type {
    return struct {
        nodes: std.ArrayList(T) = std.ArrayList(T){},
        len: usize = 0,
        allocator: std.mem.Allocator,

        const Self = @This();

        pub fn insert(self: *Self, item: T) !void {
            if (self.len == self.nodes.capacity) {
                try self.nodes.append(item);
            } else {
                self.nodes.items[self.len] = item;
                self.len += 1;
            }

            self.pushUp(self.len - 1);
        }

        pub fn extract(self: *Self) ?T {
            if (self.len == 0) return null;

            const root = self.nodes.items[0];

            std.mem.swap(T, &self.nodes.items[0], &self.nodes.items[self.len - 1]);

            self.pushDown(0);

            return root;
        }

        pub fn init(allocator: std.mem.Allocator) Self {
            return .{ .allocator = allocator };
        }

        pub fn deinit(self: *Self) void {
            self.nodes.deinit(self.allocator);
        }

        fn pushDown(self: *Self, i: usize) void {
            const c1 = 2 * i + 1;
            if (c1 >= self.len) return;

            const children = self.nodes.items[c1..@min(self.len, c1 + 2)];
            const min_child = c1 + std.mem.indexOfMin(T, children);

            if (self.nodes[min_child] < self.nodes[i]) {
                std.mem.swap(T, &self.nodes.items[i], &self.nodes.items[min_child]);
                self.pushDown(min_child);
            }
        }

        fn pushUp(self: *Self, i: usize) void {
            const p = (i - 1) / 2;

            if (self.nodes.items[i] < self.nodes.items[p]) {
                std.mem.swap(T, &self.nodes.item[i], &self.nodes.items[p]);
                self.pushUp(p);
            }
        }
    };
}

fn toggle(light: u32, button: u32) u32 {
    return (light & ~button) | (~light & button);
}

fn parseLights(input: []const u8) !u32 {
    var lights: u32 = 0;
    const one: u32 = 1;

    for (0.., input) |i, c| {
        switch (c) {
            '.' => {},
            '#' => lights |= one << @intCast(i),
            else => return AdventError.ParseError,
        }
    }

    return lights;
}

fn parseButton(input: []const u8) !u32 {
    var button: u32 = 0;
    const one: u32 = 1;
    var it = std.mem.tokenizeScalar(u8, input, ',');
    while (it.next()) |item| {
        const v = std.fmt.parseInt(u5, item, 10) catch return AdventError.ParseError;
        button |= one << v;
    }

    return button;
}

fn parseJolts(input: []const u8) ![]u32 {
    _ = input;
    return AdventError.ParseError;
}

const MachineConfig = struct {
    lights: u32,
    buttons: []u32,
    // jolts: []i32,
    //
    const Self = @This();

    pub fn parse(allocator: std.mem.Allocator, input: []const u8) !Self {
        var lights: u32 = undefined;
        var buttons_list = std.ArrayList(u32){};
        defer buttons_list.deinit(allocator);
        // var jolts: []i32 = undefined;

        var it = std.mem.tokenizeScalar(u8, input, ' ');
        while (it.next()) |item| {
            const first = item[0];
            const middle = item[1 .. item.len - 1];
            const last = item[item.len - 1];
            if (first == '[' and last == ']') {
                lights = try parseLights(middle);
            } else if (first == '(' and last == ')') {
                const button = try parseButton(middle);
                buttons_list.append(allocator, button) catch return AdventError.OutOfMemory;
            } else if (first == '{' and last == '}') {
                // jolts = parseJolts(middle);
            } else {
                return AdventError.ParseError;
            }
        }

        const buttons = allocator.alloc(u32, buttons_list.items.len) catch return AdventError.OutOfMemory;
        @memcpy(buttons, buttons_list.items);

        return .{ .lights = lights, .buttons = buttons };
    }

    pub fn deinit(self: Self, allocator: std.mem.Allocator) void {
        allocator.free(self.buttons);
    }
};

test "day 10 part 1" {
    const gpa = std.testing.allocator;

    const result = try advent.process_file(gpa, part1, "input/example_day10");
    defer gpa.free(result);

    try std.testing.expectEqualStrings("7", result);
}
