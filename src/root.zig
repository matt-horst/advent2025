const std = @import("std");

pub const AdventError = error{
    ParseError,
    OutOfMemory
};
