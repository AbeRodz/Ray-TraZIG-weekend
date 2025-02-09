const std = @import("std");
const math = std.math;
const vec = @import("vec.zig").vec3;
const Vec3 = @import("vec.zig").Vec3;
const ray = @import("ray.zig");
const rayNoTime = @import("ray.zig").rayNoTime;
const Ray = @import("ray.zig").Ray;
const HitRecord = @import("hittable.zig").HitRecord;
const Interval = @import("interval.zig").Interval;
const Material = @import("material.zig").Material;
const aabb = @import("aabb.zig").aabb;
const AABB = @import("aabb.zig").AABB;
const AABBBounded = @import("aabb.zig").AABBBounded;
const AABBBoxes = @import("aabb.zig").AABBBoxes;
const fmax = @import("rtweekend.zig").fmax;

pub const Sphere = struct {
    center: Ray,
    radius: f64,
    material: *const Material,
    bbox: aabb,

    const Self = @This();

    pub fn init(static_center: Vec3, radius: comptime_float, material: *const Material) Self {
        const rvec = vec(radius, radius, radius);
        return .{
            .center = ray.ray(static_center, vec(0, 0, 0), 0),
            .radius = fmax(0, radius),
            .material = material,
            .bbox = AABBBounded(static_center.sub(rvec), static_center.add(rvec)),
        };
    }
    pub fn getSphereUV(p: Vec3, u: *f64, v: *f64) void {
        const theta = math.acos(-p.y());
        const phi = math.atan2(-p.z(), p.x()) + math.pi;

        u.* = phi / (2 * math.pi);
        v.* = theta / math.pi;
    }
    pub fn initMoving(center1: Vec3, center2: Vec3, radius: comptime_float, material: *const Material) Self {
        var sphereTemp = Self{
            .center = rayNoTime(center1, center2.sub(center1)),
            .radius = fmax(0, radius),
            .material = material,
            .bbox = undefined,
        };

        const rvec = vec(radius, radius, radius);
        const box1 = AABBBounded(sphereTemp.center.at(0).sub(rvec), sphereTemp.center.at(0).add(center1));
        const box2 = AABBBounded(sphereTemp.center.at(1).sub(rvec), sphereTemp.center.at(1).add(rvec));
        sphereTemp.bbox = AABBBoxes(box1, box2);

        return sphereTemp;
    }
    pub fn hit(self: Self, r: Ray, interval: Interval, hit_record: *HitRecord) bool {
        const current_center = self.center.at(r.tm);
        const oc = r.origin.sub(current_center);
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
        const outward_normal = hit_record.point.sub(current_center).scalarDivision(self.radius);
        hit_record.setFaceNormal(r, outward_normal);
        getSphereUV(outward_normal, &hit_record.u, &hit_record.v);
        hit_record.material = self.material;
        return true;
    }
    pub inline fn bounding_box(self: Self) aabb {
        return self.bbox;
    }
};

pub const sphere = Sphere.init;
pub const sphereMoving = Sphere.initMoving;
