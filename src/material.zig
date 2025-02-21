const std = @import("std");
const math = std.math;
const HitRecord = @import("hittable.zig").HitRecord;
const Vec3 = @import("vec.zig").Vec3;
const vec = @import("vec.zig").vec3;
const Ray = @import("ray.zig").Ray;
const ray = @import("ray.zig").ray;
const rtweekend = @import("rtweekend.zig");
const texture = @import("texture.zig");

pub const Material = union(enum) {
    lambertian: Lambertian,
    metal: Metal,
    dielectric: Dielectric,
    diffuseLight: DiffuseLight,

    const Self = @This();
    pub fn scatter(self: Self, r: Ray, rec: HitRecord, attenuation: *Vec3, scattared: *Ray) bool {
        switch (self) {
            inline else => |s| return s.scatter(r, rec, attenuation, scattared),
        }
    }
    pub fn emitted(self: Self, u: f64, v: f64, p: *const Vec3) Vec3 {
        switch (self) {
            inline else => |s| return s.emitted(u, v, p),
        }
    }
};

pub const Lambertian = struct {
    texture: texture.Texture,

    const Self = @This();

    pub fn init(albedo: Vec3) Self {
        return .{ .texture = texture.Texture{ .solidColor = .{ .albedo = albedo } } };
    }

    pub fn initTexture(tex: texture.Texture) Self {
        return .{ .texture = tex };
    }
    pub fn scatter(self: Self, r_in: Ray, rec: HitRecord, attenuation: *Vec3, scattered: *Ray) bool {
        var scatter_direction = rec.normal.add(Vec3.randomUnitVector());
        if (scatter_direction.nearZero()) {
            scatter_direction = rec.normal;
        }
        scattered.* = ray(rec.point, scatter_direction, r_in.tm);
        attenuation.* = self.texture.value(rec.u, rec.v, &rec.point);
        return true;
    }
    pub fn emitted(_: Self, _: f64, _: f64, _: *const Vec3) Vec3 {
        return undefined;
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
        scattered.* = ray(rec.point, reflected.add(Vec3.randomUnitVector().scalarMul(self.fuzz)), r_in.tm);
        attenuation.* = self.albedo;
        return scattered.direction.dot(rec.normal) > 0;
    }
    pub fn emitted(_: Self, _: f64, _: f64, _: *const Vec3) Vec3 {
        return undefined;
    }
};

pub const Dielectric = struct {
    refraction_index: f64,
    const Self = @This();
    pub fn init(refraction_index: f64) Self {
        return .{
            .refraction_index = refraction_index,
        };
    }
    pub fn scatter(self: Self, r_in: Ray, rec: HitRecord, attenuation: *Vec3, scattered: *Ray) bool {
        attenuation.* = vec(1.0, 1.0, 1.0);

        const ri = if (rec.front_face) (1.0 / self.refraction_index) else self.refraction_index;

        const unit_direction = r_in.direction.unitVector();
        const cos_theta = rtweekend.fmin(rec.normal.dot(unit_direction.negative()), 1.0);
        const sin_theta = math.sqrt(1.0 - cos_theta * cos_theta);

        const cannot_refract = ri * sin_theta > 1.0;
        var direction: Vec3 = undefined;

        if (cannot_refract or reflectance(cos_theta, ri) > rtweekend.randomDouble()) {
            direction = Vec3.reflect(unit_direction, rec.normal);
        } else {
            direction = Vec3.refract(unit_direction, rec.normal, ri);
        }

        scattered.* = ray(rec.point, direction, r_in.tm);
        return true;
    }
    inline fn reflectance(cosine: f64, refraction_index: f64) f64 {
        // Use Schlick's approximation for reflectance.
        var r0 = (1 - refraction_index) / (1 + refraction_index);
        r0 = r0 * r0;
        return r0 + (1 - r0) * math.pow(f64, (1 - cosine), 5);
    }
    pub fn emitted(_: Self, _: f64, _: f64, _: *const Vec3) Vec3 {
        return undefined;
    }
};

pub const DiffuseLight = struct {
    texture: texture.Texture,
    const Self = @This();

    pub fn initTexture(tex: texture.Texture) Self {
        return .{ .texture = tex };
    }

    pub fn initColor(emitColor: Vec3) Self {
        return .{ .texture = texture.Texture{ .solidColor = texture.SolidColor.init(emitColor) } };
    }
    pub fn scatter(_: Self, _: Ray, _: HitRecord, _: *Vec3, _: *Ray) bool {
        return false;
    }
    pub fn emitted(self: Self, u: f64, v: f64, p: *const Vec3) Vec3 {
        return self.texture.value(u, v, p);
    }
};
