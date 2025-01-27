const std = @import("std");
pub const rand_gen = std.rand.DefaultPrng;

// constants
pub const infinity = std.math.floatMax(f64);
pub const pi = std.math.pi;

// utilities
pub fn degreesToRadians(degrees: f64) f64 {
    return degrees * pi / 180.0;
}

pub fn randomDouble() f64 {
    var seed: u64 = undefined;
    std.posix.getrandom(std.mem.asBytes(&seed)) catch |err| {
        std.debug.print("error:{}", .{err});
        return 0.5;
    };
    var prng = std.Random.DefaultPrng.init(seed);
    return prng.random().float(f64);
}
