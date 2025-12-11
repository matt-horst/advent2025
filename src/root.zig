const std = @import("std");

pub const AdventError = error{ ParseError, OutOfMemory, Overflow };

pub const AdventFn = fn (std.mem.Allocator, []const u8) AdventError![]const u8;

pub fn read_file(allocator: std.mem.Allocator, file_path: []const u8) ![]const u8 {
    const file = try std.fs.cwd().openFile(file_path, .{ .mode = .read_only });
    defer file.close();

    const stat = try file.stat();
    const file_size = stat.size;

    const buf: []u8 = try allocator.alloc(u8, file_size);
    _ = try file.read(buf);

    return buf;
}

pub fn process_file(allocator: std.mem.Allocator, f: *const AdventFn, file_path: []const u8) ![]const u8 {
    const buf = try read_file(allocator, file_path);
    defer allocator.free(buf);

    return f(allocator, buf);
}
