const std = @import("std");

// constants
pub const infinity = std.math.floatMax(f64);
pub const pi = std.math.pi;

// utilities
pub fn degreesToRadians(degrees: f64) f64 {
    return degrees * pi / 180.0;
}
