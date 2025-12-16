const std = @import("std");
const advent = @import("root.zig");
const AdventError = advent.AdventError;

pub fn part1(allocator: std.mem.Allocator, input: []const u8) AdventError![]const u8 {
    var parsed_input = try Input.parse(allocator, input);
    defer parsed_input.deinit(allocator);

    var shape_classes = allocator.alloc(ShapeClass, parsed_input.shapes.items.len) catch return AdventError.OutOfMemory;
    defer {
        for (shape_classes) |*sc| {
            sc.deinit();
        }
        allocator.free(shape_classes);
    }
    for (0.., parsed_input.shapes.items) |i, shape| {
        shape_classes[i] = try ShapeClass.init(allocator, i, shape);
    }

    var tiles = allocator.alloc([]Tile, shape_classes.len) catch return AdventError.OutOfMemory;
    defer {
        for (tiles) |ts| {
            for (ts) |*t| {
                t.deinit();
            }
            allocator.free(ts);
        }
        allocator.free(tiles);
    }

    var tm = std.AutoHashMap(u9, *Tile).init(allocator);
    defer tm.deinit();

    for (0.., shape_classes) |i, a| {
        tiles[i] = allocator.alloc(Tile, a.variants.count()) catch return AdventError.OutOfMemory;

        var j: usize = 0;
        var it = a.variants.valueIterator();
        while (it.next()) |va| {
            var tile = Tile.init(allocator, va.*);
            for (shape_classes) |b| {
                var it_b = b.variants.valueIterator();
                while (it_b.next()) |vb| {
                    try tile.addOptions(vb.*);
                }
            }

            tiles[i][j] = tile;
            tm.put(tile.shape.hash(), &tiles[i][j]) catch return AdventError.OutOfMemory;
            j += 1;
        }
    }

    var total: u32 = 0;
    for (parsed_input.regions.items) |region| {
        if (try region.canFit(allocator, tiles, tm)) {
            total += 1;
        }
    }

    const buf = std.fmt.allocPrint(allocator, "{}", .{total}) catch return AdventError.OutOfMemory;
    return buf;
}

const Wfc = struct {};

const Tile = struct {
    const OptionsSet = [5][5]std.AutoHashMap(u9, void);

    options: OptionsSet = undefined,
    shape: Shape,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, shape: Shape) Self {
        var obj: Self = .{ .shape = shape };
        for (0..5) |i| {
            for (0..5) |j| {
                obj.options[i][j] = std.AutoHashMap(u9, void).init(allocator);
            }
        }
        return obj;
    }

    pub fn deinit(self: *Self) void {
        for (0..5) |i| {
            for (0..5) |j| {
                self.options[i][j].deinit();
            }
        }
    }

    pub fn addOptions(self: *Self, shape: Shape) !void {
        for (0..5) |i| {
            for (0..5) |j| {
                if (!self.shape.intersects(shape, j, i)) {
                    self.options[i][j].put(shape.hash(), {}) catch return AdventError.OutOfMemory;
                }
            }
        }
    }
};

const Input = struct {
    shapes: std.ArrayList(Shape),
    regions: std.ArrayList(Region),

    const Self = @This();

    pub fn parse(allocator: std.mem.Allocator, input: []const u8) !Self {
        var shapes = std.ArrayList(Shape){};
        var regions = std.ArrayList(Region){};
        var it = std.mem.tokenizeSequence(u8, input, "\n\n");
        while (it.next()) |item| {
            if (std.mem.containsAtLeastScalar(u8, item, 1, 'x')) {
                var it_regions = std.mem.tokenizeScalar(u8, item, '\n');
                while (it_regions.next()) |item_region| {
                    const region = try Region.parse(allocator, item_region);
                    regions.append(allocator, region) catch return AdventError.OutOfMemory;
                }
            } else {
                const shape = Shape.parse(item);
                shapes.append(allocator, shape) catch return AdventError.OutOfMemory;
            }
        }

        return .{ .shapes = shapes, .regions = regions };
    }

    pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
        for (self.regions.items) |*region| {
            region.deinit(allocator);
        }
        self.regions.deinit(allocator);
        self.shapes.deinit(allocator);
    }

    pub fn format(self: Self, writer: *std.Io.Writer) std.Io.Writer.Error!void {
        for (0.., self.shapes.items) |i, shape| {
            try writer.print("{}:\n{f}\n", .{ i, shape });
        }

        for (self.regions.items) |region| {
            try writer.print("{f}\n", .{region});
        }
    }
};

const ShapeClass = struct {
    id: usize,
    variants: std.AutoHashMap(u9, Shape),

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, id: usize, root: Shape) !Self {
        const variants = std.AutoHashMap(u9, Shape).init(allocator);
        var obj: Self = .{ .id = id, .variants = variants };

        try obj.addVariant(root);
        try obj.addRotations(root);
        try obj.addRotations(root.flipX());
        try obj.addRotations(root.flipY());

        return obj;
    }

    pub fn deinit(self: *Self) void {
        self.variants.deinit();
    }

    fn addRotations(self: *Self, root: Shape) !void {
        var curr = root;
        for (0..3) |_| {
            curr = curr.rotate();
            try self.addVariant(curr);
        }
    }

    fn addVariant(self: *Self, root: Shape) !void {
        self.variants.put(root.hash(), root) catch return AdventError.OutOfMemory;
    }
};

const Shape = struct {
    cells: [3][3]bool,

    const Self = @This();

    pub fn parse(input: []const u8) Self {
        var cells: [3][3]bool = undefined;

        var it = std.mem.tokenizeScalar(u8, input, '\n');
        _ = it.next(); // skip the first line

        var i: usize = 0;
        while (it.next()) |line| {
            for (0.., line) |j, c| {
                cells[i][j] = c == '#';
            }

            i += 1;
        }

        return .{ .cells = cells };
    }

    pub fn format(self: Self, writer: *std.Io.Writer) std.Io.Writer.Error!void {
        for (self.cells) |row| {
            for (row) |c| {
                const char: u8 = if (c) '#' else '.';
                try writer.print("{c}", .{char});
            }
            try writer.print("\n", .{});
        }
    }

    pub fn isSymmetricX(self: Self) bool {
        for (0..3) |j| {
            if (self.cells[0][j] != self.cells[2][j]) return false;
        }

        return true;
    }

    pub fn isSymmetricY(self: Self) bool {
        for (0..3) |i| {
            if (self.cells[i][0] != self.cells[i][2]) return false;
        }

        return true;
    }

    pub fn rotate(self: Self) Self {
        var cells: [3][3]bool = undefined;
        for (0..3) |i| {
            for (0..3) |j| {
                cells[j][2 - i] = self.cells[i][j];
            }
        }

        return .{ .cells = cells };
    }

    pub fn flipX(self: Self) Self {
        var cells: [3][3]bool = undefined;
        for (0..3) |i| {
            for (0..3) |j| {
                cells[i][2 - j] = self.cells[i][j];
            }
        }

        return .{ .cells = cells };
    }

    pub fn flipY(self: Self) Self {
        var cells: [3][3]bool = undefined;
        for (0..3) |i| {
            for (0..3) |j| {
                cells[2 - i][j] = self.cells[i][j];
            }
        }

        return .{ .cells = cells };
    }

    pub fn intersects(self: Self, other: Self, x: usize, y: usize) bool {
        const low_x = @max(2, x);
        const high_x = @min(5, x + 3);

        const low_y = @max(2, y);
        const high_y = @min(5, y + 3);

        for (low_y..high_y) |i| {
            for (low_x..high_x) |j| {
                const a_i = i - 2;
                const a_j = j - 2;

                const b_i = i - y;
                const b_j = j - x;

                if (self.cells[a_i][a_j] and other.cells[b_i][b_j]) return true;
            }
        }

        return false;
    }

    pub fn hash(self: Self) u9 {
        var h: u9 = 0;
        for (0..3) |i| {
            for (0..3) |j| {
                if (self.cells[i][j]) h |= @as(u9, 1) << @intCast(3 * i + j);
            }
        }

        return h;
    }
};

const QueueNode = struct {
    i: usize,
    j: usize,
    t: *TileSet,

    fn lessThan(a: @This(), b: @This()) bool {
        return a.t.items.count() < b.t.items.count();
    }
};

const Region = struct {
    width: usize,
    height: usize,
    shapes: std.ArrayList(usize),

    const Self = @This();

    pub fn parse(allocator: std.mem.Allocator, input: []const u8) !Self {
        var it = std.mem.splitScalar(u8, input, ':');

        const dims = it.first();
        var dims_it = std.mem.splitScalar(u8, dims, 'x');
        const width = std.fmt.parseInt(usize, dims_it.first(), 10) catch return AdventError.ParseError;
        const height = std.fmt.parseInt(usize, dims_it.rest(), 10) catch return AdventError.ParseError;

        var shapes = std.ArrayList(usize){};
        var shapes_it = std.mem.tokenizeScalar(u8, it.rest(), ' ');
        while (shapes_it.next()) |item| {
            const shape_id = std.fmt.parseInt(usize, item, 10) catch return AdventError.ParseError;
            shapes.append(allocator, shape_id) catch return AdventError.OutOfMemory;
        }

        return .{ .width = width, .height = height, .shapes = shapes };
    }

    pub fn canFit(self: *const Self, allocator: std.mem.Allocator, tiles: [][]Tile, map: std.AutoHashMap(u9, *Tile)) !bool {
        var base_options = TileSet.init(allocator);
        defer base_options.deinit();

        for (0.., self.shapes.items) |i, n| {
            if (n > 0) {
                for (tiles[i]) |t| {
                    try base_options.add(t.shape.hash());
                }
            }
        }

        _ = map;

        var queue = MinHeap(QueueNode).init(allocator, QueueNode.lessThan);
        defer queue.deinit();

        var state = allocator.alloc([]TileSet, self.height) catch return AdventError.OutOfMemory;
        defer {
            for (0..self.height - 2) |i| {
                for (0..self.width - 2) |j| {
                    state[i][j].deinit();
                }
                allocator.free(state[i]);
            }
            allocator.free(state);
        }

        for (0..self.height - 2) |i| {
            state[i] = allocator.alloc(TileSet, self.width) catch return AdventError.OutOfMemory;
            for (0..self.width - 2) |j| {
                state[i][j] = try base_options.clone();
            }
        }

        return false;
    }

    pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
        self.shapes.deinit(allocator);
    }

    pub fn format(self: Self, writer: *std.Io.Writer) std.Io.Writer.Error!void {
        try writer.print("{}x{}: {any}\n", .{ self.width, self.height, self.shapes.items });
    }
};

fn canFit(allocator: std.mem.Allocator, q: MinHeap(QueueNode), state: [][]TileSet, tm: std.AutoHashMap(u9, *Tile), req: []usize) bool {
    if (std.mem.allEqual(usize, req, 0)) return true;

    if (q.extract()) |next| {
        const tile = next.t;
        var it = tile.items.keyIterator();
        while (it.next()) |v| {
            state[next.i][next.j].fix(v.*);
            // update adjacent cells options
            // 
            // if (call recursively) return true
        }
    } else {
        return false;
    }
}

fn MinHeap(comptime T: type) type {
    return struct {
        items: std.ArrayList(T) = .empty,
        lessThan: *const fn (T, T) bool,
        allocator: std.mem.Allocator,

        const Self = @This();

        pub fn init(allocator: std.mem.Allocator, lessThan: *const fn (T, T) bool) Self {
            return .{.lessThan = lessThan, .allocator = allocator };
        }

        pub fn deinit(self: *Self) void {
            self.items.deinit(self.allocator);
        }

        pub fn insert(self: *Self, item: T) !void {
            self.items.append(self.allocator, item) catch return AdventError.OutOfMemory;

            self.pushUp(self.items.items.len - 1);
        }

        pub fn extract(self: *Self) ?T {
            if (self.items.items.len == 0) return null;

            const v = self.items.items[0];

            self.items.items[0] = self.items.items[self.items.items.len - 1];
            _ = self.items.pop();

            self.pushDown(0);

            return v;
        }

        fn pushDown(self: *Self, i: usize) void {
            const len = self.items.items.len;

            const c1 = 2 * i + 1;
            const c2 = 2 * i + 2;

            if (c1 < len and self.lessThan(self.items.items[c1], self.items.items[i])) {
                if (c2 > len or self.lessThan(self.items.items[c1], self.items.items[c2])) {
                    std.mem.swap(T, &self.items.items[c1], &self.items.items[i]);
                    self.pushDown(c1);
                } else {
                    std.mem.swap(T, &self.items.items[c2], &self.items.items[i]);
                    self.pushDown(c2);
                }
            } else if (c2 < len and self.lessThan(self.items.items[c2], self.items.items[i])) {
                std.mem.swap(T, &self.items.items[c2], &self.items.items[i]);
                self.pushDown(c2);
            }
        }

        fn pushUp(self: *Self, i: usize) void {
            const p = (i - 1) / 2;

            if (self.lessThan(self.items.items[i], self.items.items[p])) {
                std.mem.swap(T, &self.items.items[i], &self.items.items[p]);
                self.pushUp(p);
            }
        }
    };
}

const TileSet = struct {
    items: std.AutoHashMap(u9, void),
    allocator: std.mem.Allocator,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Self {
        return .{ .items = std.AutoHashMap(u9, void).init(allocator), .allocator = allocator };
    }

    pub fn deinit(self: *Self) void {
        self.items.deinit();
    }

    pub fn intersect(self: *const Self, other: *const Self) !Self {
        var obj = Self.init(self.allocator);
        errdefer obj.deinit();

        var it = self.items.keyIterator();
        while (it.next()) |v| {
            if (other.items.contains(v.*)) {
                try obj.add(v.*);
            }
        }

        return obj;
    }

    pub fn add(self: *Self, v: u9) !void {
        self.items.put(v, {}) catch return AdventError.OutOfMemory;
    }

    pub fn remove(self: *Self, v: u9) bool {
        return self.items.remove(v);
    }

    pub fn merge(self: *const Self, other: *const Self) !Self {
        var obj = Self.init(self.allocator);
        errdefer obj.deinit();

        {
            var it = self.items.keyIterator();
            while (it.next()) |v| {
                try obj.add(v.*);
            }
        }

        {
            var it = other.items.keyIterator();
            while (it.next()) |v| {
                try obj.add(v.*);
            }
        }

        return obj;
    }

    pub fn clone(self: *Self) !Self {
        return .{ .items = try self.items.clone(), .allocator = self.allocator };
    }
};

test "day 12 part 1" {
    const gpa = std.testing.allocator;

    const result = try advent.process_file(gpa, part1, "input/example_day12");
    defer gpa.free(result);

    try std.testing.expectEqualStrings("2", result);
}

test "shape intersect" {
    const a = Shape{ .cells = .{ .{ true, true, true }, .{ true, false, false }, .{ true, true, true } } };
    const b = Shape{ .cells = .{ .{ false, true, true }, .{ true, true, true }, .{ false, true, true } } };

    try std.testing.expect(!a.intersects(b, 4, 2));
    try std.testing.expect(a.intersects(b, 3, 1));
}
