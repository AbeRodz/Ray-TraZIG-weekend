const std = @import("std");
pub const rand_gen = std.rand.DefaultPrng;

// constants
pub const infinity = std.math.floatMax(f64);
pub const pi = std.math.pi;

// utilities
pub inline fn degreesToRadians(degrees: f64) f64 {
    return degrees * pi / 180.0;
}

pub inline fn randomDouble() f64 {
    var seed: u64 = undefined;
    std.posix.getrandom(std.mem.asBytes(&seed)) catch |err| {
        std.debug.print("error:{}", .{err});
        return 0.5;
    };
    var prng = std.Random.DefaultPrng.init(seed);
    return prng.random().float(f64);
}

pub inline fn randomDoubleMinMax(min: f64, max: f64) f64 {
    return min + (max - min) * randomDouble();
}
pub inline fn randomInt(min: i64, max: i64) i64 {
    // Returns a random integer in [min,max].
    return @as(i64, @intFromFloat(randomDoubleMinMax(@as(f64, @floatFromInt(min)), @as(f64, @floatFromInt(max + 1)))));
}
pub inline fn randomInt16(min: u16, max: u16) u16 {
    return @min(max, @as(u16, @intFromFloat(randomDoubleMinMax(@as(f64, @floatFromInt(min)), @as(f64, @floatFromInt(max + 1))))));
}
pub inline fn randomInt8(min: u8, max: u8) u8 {
    return @min(max, @as(u8, @intFromFloat(randomDoubleMinMax(@as(f64, @floatFromInt(min)), @as(f64, @floatFromInt(max + 1))))));
}
pub inline fn fmin(a: f64, b: f64) f64 {
    return if (a < b) a else b;
}
pub inline fn fmax(a: f64, b: f64) f64 {
    return if (a > b) a else b;
}

pub inline fn fabs(n: f64) f64 {
    return if (n < 0.0) -n else n;
}
