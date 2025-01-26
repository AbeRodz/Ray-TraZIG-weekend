const std = @import("std");
const math = std.math;
const vec = @import("vec.zig");
const ray = @import("ray.zig");

pub fn hitSphere(center: vec.Vec3, radius: f64, r: ray.Ray) f64 {
    const oc = r.origin.sub(center);
    const a = r.direction.dot(r.direction);
    const b = 2.0 * oc.dot(r.direction);
    const c = oc.dot(oc) - radius * radius;
    const discriminant = b * b - 4 * a * c;
    if (discriminant < 0) {
        return -1.0;
    } else {
        return (-b - math.sqrt(discriminant)) / (2.0 * a);
    }
}
