const std = @import("std");
const math = std.math;
const vec = @import("vec.zig");
const sphere = @import("sphere.zig");

pub const Ray = struct {
    origin: vec.Vec3,
    direction: vec.Vec3,
    tm: f64,

    const Self = @This();
    pub fn init(origin: vec.Vec3, direction: vec.Vec3, tm: f64) Self {
        return Self{ .origin = origin, .direction = direction, .tm = tm };
    }
    pub fn initNoTime(origin: vec.Vec3, direction: vec.Vec3) Self {
        return Self{ .origin = origin, .direction = direction, .tm = 0 };
    }
    pub fn getOrigin(self: Self) vec.Vec3 {
        return self.origin;
    }
    pub fn getDirection(self: Self) vec.Vec3 {
        return self.direction;
    }
    pub fn getTime(self: Self) f64 {
        return self.tm;
    }

    /// Compute the point at parameter `t` along the ray
    pub fn at(self: Self, t: f64) vec.Vec3 {
        return self.origin.add(self.direction.scalarMul(t));
    }
};

pub const ray = Ray.init;
pub const rayNoTime = Ray.initNoTime;
