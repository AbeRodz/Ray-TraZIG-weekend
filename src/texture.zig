const std = @import("std");
const math = std.math;
const Vec3 = @import("vec.zig").Vec3;
const vec = @import("vec.zig").vec3;
const rtwSTB = @import("rtw_stb_image.zig");
const interval = @import("interval.zig");
const perlin = @import("perlin.zig");

pub const Texture = union(enum) {
    solidColor: SolidColor,
    checkTexture: CheckTexture,
    imageTexture: ImageTexture,
    noiseTexture: NoiseTexture,

    const Self = @This();

    pub fn value(self: Self, u: f64, v: f64, p: *const Vec3) Vec3 {
        return switch (self) {
            .solidColor => |t| t.value(u, v, p),
            .checkTexture => |t| t.value(u, v, p),
            .imageTexture => |t| t.value(u, v, p),
            .noiseTexture => |t| t.value(u, v, p),
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

    pub fn value(self: Self, u: f64, v: f64, p: *const Vec3) Vec3 {
        const xInteger = math.floor(self.invScale * p.x());
        const yInteger = math.floor(self.invScale * p.y());
        const zInteger = math.floor(self.invScale * p.z());

        const isEven = @mod(xInteger + yInteger + zInteger, 2) == 0;

        return if (isEven) self.even.value(u, v, p) else self.odd.value(u, v, p);
    }
};

pub const ImageTexture = struct {
    image: *rtwSTB.Image,

    const Self = @This();

    pub fn init(image: *rtwSTB.Image) Self {
        return .{
            .image = image,
        };
    }
    pub fn value(self: Self, u: f64, v: f64, _: *const Vec3) Vec3 {
        if (self.image.height <= 0) return vec(0, 1, 1);

        const v_i = 1.0 - interval.interval(0, 1).clamp(v); // Flip V to image coordinates

        const i = @as(i32, @intFromFloat(@floor(u * @as(f64, @floatFromInt(self.image.width)))));
        const j = @as(i32, @intFromFloat(@floor(v_i * @as(f64, @floatFromInt(self.image.height)))));

        const pixel = self.image.pixel_data(i, j);
        const color_scale = 1.0 / @as(f64, @floatFromInt(255));

        return vec(color_scale * @as(f64, @floatFromInt(pixel[0])), color_scale * @as(f64, @floatFromInt(pixel[1])), color_scale * @as(f64, @floatFromInt(pixel[2])));
    }
};

pub const NoiseTexture = struct {
    noise: *perlin.Perlin,
    scale: f64,

    const Self = @This();
    pub fn init(allocator: *std.mem.Allocator, scale: f64) !Self {
        // 1) Allocate memory on the heap for the Perlin struct
        const noise_ptr = try allocator.create(perlin.Perlin);

        // 2) Initialize that Perlin struct in-place
        noise_ptr.* = perlin.Perlin.init();

        // 3) Store that pointer in `NoiseTexture.noise`
        return .{ .noise = noise_ptr, .scale = scale };
    }
    pub fn value(self: Self, _: f64, _: f64, p: *const Vec3) Vec3 {
        return vec(0.5, 0.5, 0.5).scalarMul(self.noise.turb(p, 7)).scalarMul(1 + math.sin(self.scale * p.z() + 10));
    }
};
