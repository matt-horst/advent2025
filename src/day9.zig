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

    var it = std.mem.tokenizeScalar(u8, input, '\n');
    while (it.next()) |line| {
        var line_it = std.mem.tokenizeScalar(u8, line, ',');
        const x = std.fmt.parseInt(i32, line_it.next().?, 10) catch return AdventError.ParseError;
        const y = std.fmt.parseInt(i32, line_it.next().?, 10) catch return AdventError.ParseError;
        const p: Point = .{ .x = x, .y = y };

        points.append(allocator, p) catch return AdventError.OutOfMemory;
    }

    std.debug.assert(points.items.len % 2 == 0);
    const num_bounds = points.items.len / 2;

    var bounds_h = allocator.alloc(Line, num_bounds) catch return AdventError.OutOfMemory;
    defer allocator.free(bounds_h);

    var bounds_v = allocator.alloc(Line, num_bounds) catch return AdventError.OutOfMemory;
    defer allocator.free(bounds_v);

    var hi: usize = 0;
    var vi: usize = 0;
    for (0..points.items.len) |i| {
        // Looping from [0, len] ensures that the last point connects to first
        const prev = points.items[i % points.items.len];
        const curr = points.items[(i + 1) % points.items.len];

        if (prev.x == curr.x) {
            // The two red tiles form a horizontal line
            if (prev.y < curr.y) {
                bounds_h[hi] = .{ .a = prev, .b = curr };
            } else {
                bounds_h[hi] = .{ .a = curr, .b = prev };
            }
            hi += 1;
        } else if (prev.y == curr.y) {
            // The two red tiles form a vertical line
            if (prev.x < curr.x) {
                bounds_v[vi] = .{ .a = prev, .b = curr };
            } else {
                bounds_v[vi] = .{ .a = curr, .b = prev };
            }
            vi += 1;
        } else {
            // The two points somehow do not form an orthogonal boundary
            return AdventError.ParseError;
        }
    }

    const cmp = struct {
        fn cmp_h(_: void, a: Line, b: Line) bool {
            return a.a.y < b.a.y;
        }

        fn cmp_v(_: void, a: Line, b: Line) bool {
            return a.a.x < b.a.x;
        }
    };

    std.mem.sort(Line, bounds_h, {}, cmp.cmp_h);
    std.mem.sort(Line, bounds_v, {}, cmp.cmp_v);

    var max: u64 = 0;
    for (0.., points.items) |i, a| {
        for (points.items[i + 1 ..]) |b| {
            if (!intersects_boundary(a, b, bounds_h, bounds_v)) {
                max = @max(max, area(a, b));
                std.debug.print("a: {any}\n, b: {any}\nmax: {}\n\n", .{ a, b, max });
            }
        }
    }

    const buf = std.fmt.allocPrint(allocator, "{}", .{max}) catch return AdventError.OutOfMemory;
    return buf;
}

const Point = struct {
    x: i32,
    y: i32,
};

const Line = struct {
    a: Point,
    b: Point,
};

fn intersects_boundary(a: Point, b: Point, bounds_h: []Line, bounds_v: []Line) bool {
    // std.debug.print("checking:\na: {any}\nb:{any}\n", .{ a, b });

    const cmp = struct {
        fn cmp_h(l: Line, v: i32) Cmp {
            std.debug.assert(l.a.x == l.b.x);
            const x = l.a.x;

            if (x > v) return .gt;
            if (x < v) return .lt;
            return .eq;
        }

        fn cmp_v(l: Line, v: i32) Cmp {
            std.debug.assert(l.a.y == l.b.y);
            const y = l.a.y;

            if (y > v) return .gt;
            if (y < v) return .lt;
            return .eq;
        }
    };
    const left = @min(a.x, b.x);
    const right = @max(a.x, b.x);
    const top = @min(a.y, b.y);
    const bot = @max(a.y, b.y);

    const h1: Line = .{ .a = .{ .x = left, .y = top }, .b = .{ .x = right, .y = top } };
    const h2: Line = .{ .a = .{ .x = left, .y = bot }, .b = .{ .x = right, .y = bot } };
    for (find_boundaries_between(bounds_v, a.y, b.y, cmp.cmp_v)) |line| {
        if (intersects_line(h1, line)) {
            return true;
        }

        if (intersects_line(h2, line)) {
            return true;
        }
    }

    const v1: Line = .{ .a = .{ .x = left, .y = bot }, .b = .{ .x = left, .y = top } };
    const v2: Line = .{ .a = .{ .x = right, .y = bot }, .b = .{ .x = right, .y = top } };
    for (find_boundaries_between(bounds_h, a.x, b.x, cmp.cmp_h)) |line| {
        if (intersects_line(v1, line)) {
            return true;
        }

        if (intersects_line(v2, line)) {
            return true;
        }
    }
    return false;
}

fn intersects_line(a: Line, b: Line) bool {
    // asserting one line is horizontal and the other is vertical
    // std.debug.print("a: {any}\n, b: {any}\n", .{ a, b });
    // std.debug.assert((a.a.x == a.b.x) != (b.a.x == b.b.x));
    // std.debug.assert((a.a.y == a.b.y) != (b.a.y == b.b.y));

    if (a.a.x <= b.a.x and b.a.x <= a.b.x) {
        // A is horizontal => B is Vertical
        if (b.a.y <= a.a.y and a.a.y <= b.b.y) return true;
    }

    if (b.a.x <= a.a.x and a.a.x <= b.b.x) {
        // A is vertical => B is horizontal
        if (a.a.y <= b.a.y and b.a.y <= a.b.y) return true;
    }

    return false;
}

fn find_boundaries_between(boundaries: []Line, a: i32, b: i32, cmp: CmpFn) []Line {
    var start = binSearch(boundaries, a, cmp);
    var end = binSearch(boundaries, b, cmp);
    end = @min(end, boundaries.len - 1);
    start = @min(start, end, boundaries.len - 1);

    return boundaries[start .. end + 1];
}

const Cmp = enum { lt, eq, gt };
const CmpFn = fn (Line, i32) Cmp;

fn binSearch(boundaries: []Line, a: i32, cmp: CmpFn) usize {
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
