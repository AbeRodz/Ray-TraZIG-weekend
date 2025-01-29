const ray = @import("ray.zig");
const Ray = @import("ray.zig").Ray;
const Vec3 = @import("vec.zig").Vec3;
const Sphere = @import("sphere.zig").Sphere;
const Interval = @import("interval.zig").Interval;
const Material = @import("material.zig").Material;

pub const HitTable = union(enum) {
    sphere: Sphere,
    const Self = @This();
    pub fn hit(self: Self, r: Ray, interval: Interval, rec: *HitRecord) bool {
        switch (self) {
            inline else => |h| return h.hit(r, interval, rec),
        }
    }
};
pub const HitRecord = struct {
    point: Vec3,
    normal: Vec3,
    material: *const Material,
    t: f64,
    front_face: bool,

    const Self = @This();

    pub fn setFaceNormal(self: *Self, r: Ray, outward_normal: Vec3) void {
        self.front_face = r.direction.dot(outward_normal) < 0;
        self.normal = if (self.front_face) outward_normal else outward_normal.negative();
    }
};
