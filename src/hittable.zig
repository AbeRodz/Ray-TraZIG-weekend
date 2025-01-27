const ray = @import("ray.zig");
const Ray = @import("ray.zig").Ray;
const Vec3 = @import("vec.zig").Vec3;
const Sphere = @import("sphere.zig").Sphere;

pub const HitTable = union(enum) {
    sphere: Sphere,
    const Self = @This();
    pub fn hit(self: Self, r: Ray, ray_tmin: f64, ray_tmax: f64, rec: *HitRecord) bool {
        switch (self) {
            inline else => |h| return h.hit(r, ray_tmin, ray_tmax, rec),
        }
    }
};
pub const HitRecord = struct {
    point: Vec3,
    normal: Vec3,
    t: f64,
    front_face: bool,

    const Self = @This();

    pub fn setFaceNormal(self: *Self, r: Ray, outward_normal: Vec3) void {
        self.front_face = r.direction.dot(outward_normal) < 0;
        self.normal = if (self.front_face) outward_normal else outward_normal.negative();
    }
};
