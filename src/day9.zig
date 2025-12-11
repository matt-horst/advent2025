const std = @import("std");
const advent = @import("root.zig");
const AdventError = advent.AdventError;

pub fn part1(allocator: std.mem.Allocator, input: []const u8) AdventError![]const u8 {
    var max: u64 = 0;
    var ps = std.ArrayList(Point){};
    defer ps.deinit(allocator);

    var it = std.mem.tokenizeScalar(u8, input, '\n');
    while (it.next()) |line| {
        var line_it = std.mem.tokenizeScalar(u8, line, ',');
        const x = std.fmt.parseInt(i32, line_it.next().?, 10) catch return AdventError.ParseError;
        const y = std.fmt.parseInt(i32, line_it.next().?, 10) catch return AdventError.ParseError;
        const p: Point = .{ .x = x, .y = y };

        ps.append(allocator, p) catch return AdventError.OutOfMemory;
    }

    for (0.., ps.items) |i, a| {
        for (ps.items[i + 1 ..]) |b| {
            max = @max(max, area(a, b));
        }
    }

    const buf = std.fmt.allocPrint(allocator, "{d}", .{max}) catch return AdventError.OutOfMemory;
    return buf;
}

fn area(a: Point, b: Point) u64 {
    const dx: u64 = @abs(a.x - b.x + 1);
    const dy: u64 = @abs(a.y - b.y + 1);
    return dx * dy;
}

pub fn part2(allocator: std.mem.Allocator, input: []const u8) AdventError![]const u8 {
    var points = std.ArrayList(Point){};
    defer points.deinit(allocator);

    var xlimit: usize = 0;
    var ylimit: usize = 0;

    var it = std.mem.tokenizeScalar(u8, input, '\n');
    while (it.next()) |line| {
        var line_it = std.mem.tokenizeScalar(u8, line, ',');
        const x = std.fmt.parseInt(i32, line_it.next().?, 10) catch return AdventError.ParseError;
        const y = std.fmt.parseInt(i32, line_it.next().?, 10) catch return AdventError.ParseError;
        const p: Point = .{ .x = x, .y = y };

        points.append(allocator, p) catch return AdventError.OutOfMemory;
        xlimit = @max(xlimit, x);
        ylimit = @max(ylimit, y);
    }

    std.debug.assert(points.items.len % 2 == 0);
    const num_bounds = points.items.len;

    var bounds_h = allocator.alloc(Line, num_bounds) catch return AdventError.OutOfMemory;
    defer allocator.free(bounds_h);

    var bounds_v = allocator.alloc(Line, num_bounds) catch return AdventError.OutOfMemory;
    defer allocator.free(bounds_v);

    for (0..points.items.len) |i| {
        // Looping from [0, len) ensures that the last point connects to first
        const prev = points.items[i];
        const curr = points.items[(i + 1) % points.items.len];

        bounds_h[i] = Line.create(prev, curr);
        bounds_v[i] = Line.create(prev, curr);
    }

    std.mem.sort(Line, bounds_h, {}, Line.lessThanH);
    std.mem.sort(Line, bounds_v, {}, Line.lessThanV);

    std.debug.print("\nbh: {any}\n", .{bounds_h});
    std.debug.print("bv: {any}\n\n", .{bounds_v});

    std.debug.print("\nx: {}, y: {}\n", .{ xlimit, ylimit });
    // print(allocator, bounds_h, bounds_v, xlimit + 1, ylimit + 1) catch return AdventError.OutOfMemory;

    var max: u64 = 0;
    var best_a: Point = undefined;
    var best_b: Point = undefined;
    for (0.., points.items) |i, a| {
        for (points.items[i + 1 ..]) |b| {
            // std.debug.print("a: {any}, b: {any}\n", .{ a, b });
            const center: Point = .{ .x = @divFloor(a.x + b.x, 2), .y = @divFloor(a.y + b.y, 2) };
            const box = Box.create(a, b);
            const box_area = box.area();
            if (box_area > max and !crossesBoundary(box, bounds_h, bounds_v) and isInterior(center, bounds_h, bounds_v)) {
                best_a = a;
                best_b = b;
                max = box_area;
                // std.debug.print("a: {any}\nb: {any}\nmax: {}\n\n", .{ a, b, max });
            }
        }
    }
    std.debug.print("a: {any}, b: {any}\n", .{ best_a, best_b });

    const buf = std.fmt.allocPrint(allocator, "{}", .{max}) catch return AdventError.OutOfMemory;
    return buf;
}

fn print(allocator: std.mem.Allocator, bh: []Line, bv: []Line, xlimit: usize, ylimit: usize) !void {
    var tiles = try allocator.alloc([]Tile, ylimit);
    defer {
        for (tiles) |row| allocator.free(row);
        allocator.free(tiles);
    }

    for (0.., tiles) |i, _| {
        tiles[i] = try allocator.alloc(Tile, xlimit);
        for (0.., tiles[i]) |j, _| {
            tiles[i][j] = .empty;
        }
    }

    for (bh) |line| {
        tiles[@intCast(line.a.y)][@intCast(line.a.x)] = .red;
        tiles[@intCast(line.b.y)][@intCast(line.b.x)] = .red;

        switch (line.dir) {
            .horz => {
                const y: usize = @intCast(line.a.y);
                const x1: usize = @intCast(line.a.x);
                const x2: usize = @intCast(line.b.x);

                for (x1 + 1..x2) |x| {
                    tiles[y][x] = .green;
                }
            },
            .vert => {
                const x: usize = @intCast(line.a.x);
                const y1: usize = @intCast(line.a.y);
                const y2: usize = @intCast(line.b.y);

                for (y1 + 1..y2) |y| {
                    tiles[y][x] = .green;
                }
            },
            else => {},
        }
    }

    for (0..ylimit) |y| {
        for (0..xlimit) |x| {
            if (isInterior(.{ .x = @intCast(x), .y = @intCast(y) }, bh, bv)) {
                tiles[y][x] = .green;
            }
        }
    }

    for (tiles) |row| {
        for (row) |c| {
            std.debug.print("{c}", .{@intFromEnum(c)});
        }
        std.debug.print("\n", .{});
    }
    std.debug.print("\n", .{});
}

const Tile = enum(u8) {
    empty = '.',
    green = 'X',
    red = '#',
};

const Point = struct {
    x: i32,
    y: i32,
};

const Dir = enum { horz, vert, diag };

const Line = struct {
    a: Point,
    b: Point,
    dir: Dir,

    const Self = @This();

    pub fn create(a: Point, b: Point) Self {
        const tl: Point = .{ .x = @min(a.x, b.x), .y = @min(a.y, b.y) };
        const br: Point = .{ .x = @max(a.x, b.x), .y = @max(a.y, b.y) };
        const dir: Dir = if (a.x == b.x) .vert else if (a.y == b.y) .horz else .diag;

        return .{ .a = tl, .b = br, .dir = dir };
    }

    pub fn cmp(self: Self, v: i32) Cmp {
        return switch (self.dir) {
            .horz => if (v < self.a.y) .lt else if (v > self.a.y) .gt else .eq,
            .vert => if (v < self.a.x) .lt else if (v > self.a.x) .gt else .eq,
            else => unreachable,
        };
    }

    pub fn lessThanH(_: void, self: Self, other: Self) bool {
        return self.a.y < other.a.y;
    }

    pub fn lessThanV(_: void, self: Self, other: Self) bool {
        return self.a.x < other.a.x;
    }

    pub fn area(self: Self) i32 {
        const dx = self.b.x - self.a.x;
        const dy = self.b.y - self.a.y;
        return (dx + 1) * (dy + 1);
    }
};

const Box = struct {
    diag: Line,
    top: Line,
    left: Line,
    right: Line,
    bot: Line,

    const Self = @This();

    pub fn create(a: Point, b: Point) Self {
        const diag = Line.create(a, b);
        const width = diag.b.x - diag.a.x + 1;
        const height = diag.b.y - diag.a.y + 1;
        
        var tl = diag.a;
        if (width > 1) tl.x += 1;
        if (height > 1) tl.y += 1;

        var br = diag.b;
        if (width > 1) br.x -= 1;
        if (height > 1) br.x -= 1;

        const tr: Point = .{ .x = br.x, .y = tl.y };
        const bl: Point = .{ .x = tl.x, .y = br.y };

        const top = Line.create(tl, tr);
        const bot = Line.create(bl, br);
        const left = Line.create(tl, bl);
        const right = Line.create(tr, br);

        return .{ .top = top, .left = left, .right = right, .bot = bot, .diag = diag };
    }

    pub fn area(self: Self) u64 {
        const dx: u64 = @intCast(@abs(self.diag.b.x - self.diag.a.x));
        const dy: u64 = @intCast(@abs(self.diag.b.y - self.diag.a.y));

        return (dx + 1) * (dy + 1);
    }
};

fn crossesBoundary(box: Box, bounds_h: []Line, bounds_v: []Line) bool {
    for (bounds_v) |line| {
        if (crossesLine(box.top, line)) {
            return true;
        }

        if (crossesLine(box.bot, line)) {
            return true;
        }
    }

    for (bounds_h) |line| {
        if (crossesLine(box.left, line)) {
            return true;
        }

        if (crossesLine(box.right, line)) {
            return true;
        }
    }

    return false;
}

fn intersectsLine(a: Line, b: Line) bool {
    if (a.a.x == 7 and a.a.y == 1 and a.b.x == 11 and a.b.y == 1 and b.a.x == -1 and b.a.y == 5 and b.b.x == 9 and b.b.y == 5) {
        std.debug.print("here\n", .{});
    }
    if (a.dir == b.dir) {
        switch (a.dir) {
            .horz => {
                if (a.a.y != b.a.y) return false;
                return (b.a.x <= a.b.x and a.b.x <= b.b.x) or (a.a.x <= b.a.x and b.a.x <= a.b.x);
            },
            .vert => {
                if (a.a.x != b.a.x) return false;
                return (b.a.y <= a.b.y and a.b.y <= b.b.y) or (a.a.y <= b.a.y and b.a.y <= a.b.y);
            },
            else => unreachable,
        }
    }

    switch (a.dir) {
        .horz => {
            const y = a.a.y;
            if (y < b.a.y or y > b.b.y) return false;

            const x = b.a.x;
            if (x < a.a.x or x > a.b.x) return false;

            return true;
        },
        .vert => {
            const y = b.a.y;
            if (y < a.a.y or y > a.b.y) return false;

            const x = a.a.x;
            if (x < b.a.x or x > b.b.x) return false;

            return true;
        },
        else => unreachable,
    }
}

fn crossesLine(a: Line, b: Line) bool {
    if (a.dir == b.dir) {
        return false;
    }

    switch (a.dir) {
        .horz => {
            const y = a.a.y;
            const x = b.a.x;

            return (b.a.y < y and y < b.b.y) and (a.a.x < x and x < a.b.x);
        },
        .vert => {
            const y = b.a.y;
            const x = a.a.x;

            return (b.a.x < x and x < b.b.x) and (a.a.y < y and y < a.b.y);
        },
        else => unreachable,
    }
}

fn isInterior(p: Point, bounds_h: []Line, bounds_v: []Line) bool {
    var count_left: u32 = 0;
    const ray_h = Line.create(p, .{ .x = -1, .y = p.y });
    for (bounds_v) |line| {
        // if (line.a.x > p.x) break;
        if (isInside(p, line)) return true;

        if (intersectsLine(line, ray_h)) {
            if (p.x == 9 and p.y == 5) {
                std.debug.print("{any} intersects {any}: {}\n", .{ line, ray_h, intersectsLine(line, ray_h) });
            }
            count_left += 1;
        }
    }

    if (count_left % 2 != 1) return false;

    var count_up: u32 = 0;
    const ray_v = Line.create(p, .{ .x = p.x, .y = -1 });
    for (bounds_h) |line| {
        // if (line.a.y > p.y) break;
        if (isInside(p, line)) return true;

        if (intersectsLine(line, ray_v)) {
            if (p.x == 9 and p.y == 5) {
                std.debug.print("{any} intersects {any}\n", .{ line, ray_v });
            }
            count_up += 1;
        }
    }

    return count_up % 2 == 1;
}

fn isInside(p: Point, line: Line) bool {
    return switch (line.dir) {
        .horz => (p.y == line.a.y and line.a.x <= p.x and p.x <= line.b.x),
        .vert => (p.x == line.a.x and line.a.y <= p.y and p.y <= line.b.y),
        else => unreachable
    };
}

fn findBoundariesBetween(comptime T: type, boundaries: []T, a: i32, b: i32, cmp: CmpFn(T)) []T {
    var start = binSearch(T, boundaries, a, cmp);
    var end = binSearch(T, boundaries, b, cmp);
    end = @min(end, boundaries.len - 1);
    start = @min(start, end, boundaries.len - 1);
    // std.debug.print("between: [{}, {}] -> [{}, {}]\n", .{ a, b, start, end });

    return boundaries[start .. end + 1];
}

const Cmp = enum { lt, eq, gt };
fn CmpFn(comptime T: type) type {
    return fn (T, i32) Cmp;
}

fn binSearch(comptime T: type, boundaries: []T, a: i32, cmp: CmpFn(T)) usize {
    if (cmp(boundaries[0], a) == .lt) {
        return 0;
    }

    if (cmp(boundaries[boundaries.len - 1], a) == .gt) {
        return boundaries.len;
    }

    var l: usize = 0;
    var r: usize = boundaries.len;

    while (l <= r) {
        const m = l + (r - l) / 2;
        switch (cmp(boundaries[m], a)) {
            .lt => r = m - 1,
            .gt => l = m + 1,
            .eq => return m,
        }
    }

    return l;
}

test "day 9 part 1" {
    const gpa = std.testing.allocator;

    const result = try advent.process_file(gpa, part1, "input/example_day9");
    defer gpa.free(result);

    try std.testing.expectEqualStrings("50", result);
}

test "day 9 part 2" {
    const gpa = std.testing.allocator;

    const result = try advent.process_file(gpa, part2, "input/example_day9");
    defer gpa.free(result);

    try std.testing.expectEqualStrings("24", result);
}

test "lines intersect" {
    // const a = Line{ point, .y1 = 0, .y2 = 4 };
    // const b = Line{ .y = 2, .x1 = 0, .x2 = 4 };
    //
    // try std.testing.expect(intersectsLine(a, b));
}
