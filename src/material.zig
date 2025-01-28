const HitTable = @import("hittable.zig").HitTable;
const HitRecord = @import("hittable.zig").HitRecord;
const Vec3 = @import("vec.zig").Vec3;
const Ray = @import("ray.zig").Ray;
const ray = @import("ray.zig").ray;
pub const Material = union(enum) {
    lambertian: Lambertian,
    metal: Metal,

    const Self = @This();
    pub fn scatter(self: Self, r: Ray, rec: HitRecord, attenuation: *Vec3, scattared: *Ray) bool {
        switch (self) {
            inline else => |s| return s.scatter(r, rec, attenuation, scattared),
        }
    }
};

pub const Lambertian = struct {
    albedo: Vec3,
    const Self = @This();
    pub fn init(c: Vec3) Self {
        return .{
            .albedo = c,
        };
    }
    pub fn scatter(self: Self, r_in: Ray, rec: HitRecord, attenuation: *Vec3, scattered: *Ray) bool {
        _ = r_in;
        var scatter_direction = rec.normal.add(Vec3.randomUnitVector());
        if (scatter_direction.nearZero()) {
            scatter_direction = rec.normal;
        }
        scattered.* = ray(rec.point, scatter_direction);
        attenuation.* = self.albedo;
        return true;
    }
};

pub const Metal = struct {
    albedo: Vec3,
    fuzz: f64,
    const Self = @This();
    pub fn init(a: Vec3, f: f64) Self {
        return .{
            .albedo = a,
            .fuzz = if (f < 1) f else 1,
        };
    }
    pub fn scatter(self: Self, r_in: Ray, rec: HitRecord, attenuation: *Vec3, scattered: *Ray) bool {
        const reflected = Vec3.reflect(r_in.direction.unitVector(), rec.normal);
        scattered.* = ray(rec.point, reflected.add(Vec3.randomUnitVector().scalarMul(self.fuzz)));
        attenuation.* = self.albedo;
        return scattered.direction.dot(rec.normal) > 0;
    }
};
