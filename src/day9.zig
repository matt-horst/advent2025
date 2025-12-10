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
    const num_bounds = points.items.len / 2;

    var bounds_h = allocator.alloc(HLine, num_bounds) catch return AdventError.OutOfMemory;
    defer allocator.free(bounds_h);

    var bounds_v = allocator.alloc(VLine, num_bounds) catch return AdventError.OutOfMemory;
    defer allocator.free(bounds_v);

    var hi: usize = 0;
    var vi: usize = 0;
    for (0..points.items.len) |i| {
        // Looping from [0, len] ensures that the last point connects to first
        const prev = points.items[i % points.items.len];
        const curr = points.items[(i + 1) % points.items.len];

        if (prev.y == curr.y) {
            // The two red tiles form a horizontal line
            bounds_h[hi] = HLine.create(prev, curr);
            hi += 1;
        } else if (prev.x == curr.x) {
            // The two red tiles form a vertical line
            bounds_v[vi] = VLine.create(prev, curr);
            vi += 1;
        } else {
            // The two points somehow do not form an orthogonal boundary
            return AdventError.ParseError;
        }
    }

    std.mem.sort(HLine, bounds_h, {}, HLine.lessThan);
    std.mem.sort(VLine, bounds_v, {}, VLine.lessThan);

    std.debug.print("\nx: {}, y: {}\n", .{ xlimit, ylimit });
    print(allocator, bounds_h, bounds_v, xlimit + 1, ylimit + 1) catch return AdventError.OutOfMemory;

    var max: u64 = 0;
    var best_a: Point = undefined;
    var best_b: Point = undefined;
    for (0.., points.items) |i, a| {
        for (points.items[i + 1 ..]) |b| {
            // std.debug.print("a: {any}, b: {any}\n", .{ a, b });
            const center: Point = .{ .x = @divFloor(a.x + b.x, 2), .y = @divFloor(a.y + b.y, 2) };
            const curr_area = area(a, b);
            if (curr_area > max and !intersectsBoundary(a, b, bounds_h, bounds_v) and isInterior(center, bounds_h, bounds_v)) {
                best_a = a;
                best_b = b;
                max = curr_area;
                // std.debug.print("a: {any}\nb: {any}\nmax: {}\n\n", .{ a, b, max });
            }
        }
    }
    std.debug.print("a: {any}, b: {any}\n", .{best_a, best_b});

    const buf = std.fmt.allocPrint(allocator, "{}", .{max}) catch return AdventError.OutOfMemory;
    return buf;
}

fn print(allocator: std.mem.Allocator, bh: []HLine, bv: []VLine, xlimit: usize, ylimit: usize) !void {
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
        const y: usize = @intCast(line.y);
        const x1: usize = @intCast(line.x1);
        const x2: usize = @intCast(line.x2);

        tiles[y][x1] = .red;
        tiles[y][x2] = .red;

        for (x1 + 1..x2) |x| {
            tiles[y][x] = .green;
        }
    }

    for (bv) |line| {
        const x: usize = @intCast(line.x);
        const y1: usize = @intCast(line.y1);
        const y2: usize = @intCast(line.y2);

        tiles[y1][x] = .red;
        tiles[y2][x] = .red;

        for (y1 + 1..y2) |y| {
            tiles[y][x] = .green;
        }
    }

    for (0..ylimit) |y| {
        for (0..xlimit) |x| {
            if (isInterior(.{.x = @intCast(x), .y = @intCast(y)}, bh, bv)) {
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

const VLine = struct {
    y1: i32,
    y2: i32,
    x: i32,

    const Self = @This();

    pub fn create(a: Point, b: Point) Self {
        std.debug.assert(a.x == b.x);

        return .{ .x = a.x, .y1 = @min(a.y, b.y), .y2 = @max(a.y, b.y) };
    }

    pub fn cmp(self: Self, x: i32) Cmp {
        if (x < self.x) return .lt;
        if (x > self.x) return .gt;
        return .eq;
    }

    pub fn lessThan(_: void, self: Self, other: Self) bool {
        return self.x < other.x;
    }
};

const HLine = struct {
    x1: i32,
    x2: i32,
    y: i32,

    const Self = @This();

    pub fn create(a: Point, b: Point) Self {
        std.debug.assert(a.y == b.y);

        return .{ .y = a.y, .x1 = @min(a.x, b.x), .x2 = @max(a.x, b.x) };
    }

    pub fn cmp(self: Self, y: i32) Cmp {
        if (y < self.y) return .lt;
        if (y > self.y) return .gt;
        return .eq;
    }

    pub fn lessThan(_: void, self: Self, other: Self) bool {
        return self.y < other.y;
    }
};

fn intersectsBoundary(a: Point, b: Point, bounds_h: []HLine, bounds_v: []VLine) bool {
    const left = @min(a.x, b.x);
    const right = @max(a.x, b.x);
    const top = @min(a.y, b.y);
    const bot = @max(a.y, b.y);

    // std.debug.print("top: {}, bot: {}, left: {}, right: {}\n", .{ top, bot, left, right });

    const h1: HLine = .{ .y = top, .x1 = left, .x2 = right };
    const h2: HLine = .{ .y = bot, .x1 = left, .x2 = right };
    // for (findBoundariesBetween(VLine, bounds_v, left, right, VLine.cmp)) |line| {
    for (bounds_v) |line| {
        if (line.x <= left) continue;
        if (line.x >= right) break;

        if (intersectsLine(h1, line)) {
            return true;
        }

        if (intersectsLine(h2, line)) {
            return true;
        }
    }

    const v1: VLine = .{ .x = left, .y1 = bot, .y2 = top };
    const v2: VLine = .{ .x = right, .y1 = bot, .y2 = top };
    // for (findBoundariesBetween(HLine, bounds_h, bot, top, HLine.cmp)) |line| {
    for (bounds_h) |line| {
        if (line.y <= bot) continue;
        if (line.y >= top) break;

        if (intersectsLine(line, v1)) {
            return true;
        }

        if (intersectsLine(line, v2)) {
            return true;
        }
    }
    return false;
}

fn intersectsLine(a: anytype, b: anytype) bool {
    var hline: HLine = undefined;
    var vline: VLine = undefined;

    std.debug.assert(@TypeOf(a) != @TypeOf(b));

    switch (@TypeOf(a)) {
        HLine => hline = a,
        VLine => vline = a,
        else => unreachable,
    }

    switch (@TypeOf(b)) {
        HLine => hline = b,
        VLine => vline = b,
        else => unreachable,
    }

    if ((vline.x < hline.x1) or (vline.x > hline.x2)) {
        // std.debug.print("{any} intersects {any}: false\n", .{ a, b });
        return false;
    }
    if ((hline.y < vline.y1) or (hline.y > vline.y2)) {
        // std.debug.print("{any} intersects {any}: false\n", .{ a, b });
        return false;
    }

    // std.debug.print("{any} intersects {any}: true\n", .{ a, b });
    return true;
}

fn isInterior(p: Point, bounds_h: []HLine, bounds_v: []VLine) bool {
    var count_left: u32 = 0;
    const ray_h = HLine.create(p, .{ .x = -1, .y = p.y });
    for (bounds_v) |line| {
        if (line.x > p.x) break;

        if (intersectsLine(line, ray_h)) {
            count_left += 1;
        }
    }

    if (count_left % 2 != 1) return false;

    var count_up: u32 = 0;
    const ray_v = VLine.create(p, .{ .x = p.x, .y = -1 });
    for (bounds_h) |line| {
        if (line.y > p.y) break;

        if (intersectsLine(line, ray_v)) {
            count_up += 1;
        }
    }

    return count_up % 2 == 1;
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
    const a = VLine{ .x = 2, .y1 = 0, .y2 = 4 };
    const b = HLine{ .y = 2, .x1 = 0, .x2 = 4 };

    try std.testing.expect(intersectsLine(a, b));
}
