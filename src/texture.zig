const std = @import("std");
const math = std.math;
const Vec3 = @import("vec.zig").Vec3;
const vec = @import("vec.zig").vec3;

pub const Texture = union(enum) {
    solidColor: SolidColor,
    checkTexture: CheckTexture,

    const Self = @This();

    pub fn value(self: Self, u: f64, v: f64, p: *const Vec3) Vec3 {
        return switch (self) {
            .solidColor => |t| t.value(u, v, p),
            .checkTexture => |t| t.value(u, v, p),
        };
    }
};

pub const SolidColor = struct {
    albedo: Vec3,

    const Self = @This();

    pub fn init(albedo: Vec3) Self {
        return .{ .albedo = albedo };
    }
    pub fn value(self: Self, _: f64, _: f64, _: *const Vec3) Vec3 {
        return self.albedo;
    }

    pub fn solidColor(red: f64, green: f64, blue: f64) Self {
        return init(vec(red, green, blue));
    }
};

pub const CheckTexture = struct {
    invScale: f64,
    even: *Texture,
    odd: *Texture,

    const Self = @This();

    pub fn init(scale: f64, even: *Texture, odd: *Texture) Self {
        return .{
            .invScale = 1.0 / scale,
            .even = even,
            .odd = odd,
        };
    }
    pub fn checkerTextureByColor(scale: f64, color1: *Vec3, color2: *Vec3) Self {
        const even = Texture{ .solidColor = SolidColor.init(color1) };
        const odd = Texture{ .solidColor = SolidColor.init(color2) };
        return Self.init(scale, even, odd);
    }
    //     pub fn checkerTextureByColor(allocator: *std.mem.Allocator, scale: f64, color1: Vec3, color2: Vec3) !Self {
    //     const even = try allocator.create(Texture);
    //     even.* = Texture{ .solidColor = SolidColor.init(color1) };

    //     const odd = try allocator.create(Texture);
    //     odd.* = Texture{ .solidColor = SolidColor.init(color2) };

    //     return Self.init(scale, even, odd);
    // }
    pub fn value(self: Self, u: f64, v: f64, p: *const Vec3) Vec3 {
        const xInteger = math.floor(self.invScale * p.x());
        const yInteger = math.floor(self.invScale * p.y());
        const zInteger = math.floor(self.invScale * p.z());

        const isEven = @mod(xInteger + yInteger + zInteger, 2) == 0;

        return if (isEven) self.even.value(u, v, p) else self.odd.value(u, v, p);
    }
};
