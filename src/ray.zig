const std = @import("std");
const math = std.math;
const vec = @import("vec.zig");
const sphere = @import("sphere.zig");

pub const Ray = struct {
    origin: vec.Vec3,
    direction: vec.Vec3,

    pub fn init(origin: vec.Vec3, direction: vec.Vec3) Ray {
        return Ray{
            .origin = origin,
            .direction = direction,
        };
    }
    pub fn getOrigin(self: Ray) vec.Vec3 {
        return self.origin;
    }
    pub fn getDirection(self: Ray) vec.Vec3 {
        return self.direction;
    }

    /// Compute the point at parameter `t` along the ray
    pub fn at(self: Ray, t: f64) vec.Vec3 {
        return self.origin.add(self.direction.scalarMul(t));
    }
};

pub const ray = Ray.init;
