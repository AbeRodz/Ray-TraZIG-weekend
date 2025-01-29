const std = @import("std");
const math = std.math;
const vec = @import("vec.zig");
const Vec3 = @import("vec.zig").Vec3;
const ray = @import("ray.zig");
const Ray = @import("ray.zig").Ray;
const HitRecord = @import("hittable.zig").HitRecord;
const Interval = @import("interval.zig").Interval;
const Material = @import("material.zig").Material;

pub const Sphere = struct {
    center: Vec3,
    radius: f64,
    material: *const Material,

    const Self = @This();

    pub fn init(center: Vec3, radius: f64, material: *const Material) Self {
        return .{
            .center = center,
            .radius = radius,
            .material = material,
        };
    }
    pub fn hit(self: Self, r: Ray, interval: Interval, hit_record: *HitRecord) bool {
        const oc = r.origin.sub(self.center);
        const a = r.direction.lengthSquared();
        const half_b = oc.dot(r.direction);
        const c = oc.lengthSquared() - self.radius * self.radius;

        const discriminant = half_b * half_b - a * c;
        if (discriminant < 0) return false;
        const sqrtd = math.sqrt(discriminant);

        var root = (-half_b - sqrtd) / a;
        if (!interval.surronds(root)) {
            root = (-half_b + sqrtd) / a;
            if (!interval.surronds(root))
                return false;
        }

        hit_record.t = root;
        hit_record.point = r.at(hit_record.t);
        const outward_normal = hit_record.point.sub(self.center).scalarDivision(self.radius);
        hit_record.setFaceNormal(r, outward_normal);
        hit_record.material = self.material;
        return true;
    }
};

pub const sphere = Sphere.init;
