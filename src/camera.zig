const std = @import("std");
const math = std.math;
const vec = @import("vec.zig");
const color = @import("color.zig");
const randomOnHemisphere = @import("vec.zig").Vec3.randomOnHemisphere;
const Vec3 = @import("vec.zig").Vec3;
const vec3 = @import("vec.zig").vec3;
const Ray = @import("ray.zig").Ray;
const ray = @import("ray.zig").ray;
const HitTableList = @import("hittable_list.zig").HitTableList;
const HitRecord = @import("hittable.zig").HitRecord;
const interval = @import("interval.zig").interval;
const rtweekend = @import("rtweekend.zig");

pub const Camera = struct {
    aspect_ratio: f64,
    image_height: u32,
    image_width: u32,
    focal_length: f64,
    viewport_height: f64,
    camera_center: Vec3,
    pixel00_loc: Vec3,
    pixel_delta_u: Vec3,
    pixel_delta_v: Vec3,
    samples_per_pixel: u32 = 10,
    max_depth: u32 = 10,

    const Self = @This();

    pub fn init(
        aspect_ratio: f64,
        image_width: u32,
        focal_length: f64,
        viewport_height: f64,
        camera_center: Vec3,
    ) Camera {
        return Camera{
            .aspect_ratio = aspect_ratio,
            .image_width = image_width,
            .focal_length = focal_length,
            .viewport_height = viewport_height,
            .camera_center = camera_center,

            .image_height = undefined,
            .pixel00_loc = undefined,
            .pixel_delta_u = undefined,
            .pixel_delta_v = undefined,
        };
    }
    pub fn initialize(self: *Self) void {
        self.image_height = @as(u32, @intFromFloat(@as(f32, @floatFromInt(self.image_width)) / self.aspect_ratio));
        self.image_height = if (self.image_height < 1) 1 else self.image_height;

        //const focal_length = 1.0;
        //const viewport_height = 2.0;
        const viewport_width = self.viewport_height * (@as(f64, @floatFromInt(self.image_width)) / @as(f64, @floatFromInt(self.image_height)));

        const viewport_u = vec3(viewport_width, 0, 0);
        const viewport_v = vec3(0, -self.viewport_height, 0);

        self.pixel_delta_u = viewport_u.scalarDivision(@floatFromInt(self.image_width));
        self.pixel_delta_v = viewport_v.scalarDivision(@floatFromInt(self.image_height));

        const viewport_upper_left = self.camera_center.sub(vec3(0, 0, self.focal_length)).sub(viewport_u.scalarDivision(2)).sub(viewport_v.scalarDivision(2));
        self.pixel00_loc = viewport_upper_left.add(self.pixel_delta_u.add(self.pixel_delta_v).scalarMul(0.5));
    }

    pub fn render(self: *Self, world: HitTableList) !void {
        self.initialize();

        var buffered_writer = std.io.bufferedWriter(std.io.getStdOut().writer());
        const writer = buffered_writer.writer();
        try writer.print("P3\n{d} {d}\n255\n", .{ self.image_width, self.image_height });
        {
            for (0..self.image_height) |j| {
                for (0..self.image_width) |i| {
                    var pixel_color = vec3(0, 0, 0);

                    for (0..self.samples_per_pixel) |_| {
                        const r = self.getRay(i, j);
                        pixel_color = pixel_color.add(rayColor(r, self.max_depth, world));
                    }

                    try color.write_color(writer, pixel_color, self.samples_per_pixel);
                }
            }
        }
        try buffered_writer.flush();
        std.debug.print("PPM file generated successfully.\n", .{});
    }
    fn rayColor(r: Ray, depth: u32, world: HitTableList) Vec3 {
        if (depth <= 0) {
            return vec3(0, 0, 0);
        }
        var hit_record: HitRecord = undefined;
        if (world.hit(r, interval(0.001, rtweekend.infinity), &hit_record)) {
            const direction = randomOnHemisphere(hit_record.normal);
            return rayColor(ray(hit_record.point, direction), depth - 1, world).scalarMul(0.5);
        }
        const unit_direction = r.direction.unitVector();
        const a = 0.5 * (unit_direction.y + 1.0);
        return vec3(1, 1, 1).scalarMul(1.0 - a).add(vec3(0.5, 0.7, 1.0).scalarMul(a));
    }

    fn getRay(self: Self, i: usize, j: usize) Ray {
        const i_f = @as(f64, @floatFromInt(i));
        const j_f = @as(f64, @floatFromInt(j));
        const offset = sampleSquare();

        const pixel_sample = self.pixel00_loc.add(self.pixel_delta_u.scalarMul((offset.x + i_f)).add(self.pixel_delta_v.scalarMul((offset.y + j_f))));
        const ray_origin = self.camera_center;
        const ray_direction = pixel_sample.sub(ray_origin);
        return ray(ray_origin, ray_direction);
    }
};

fn sampleSquare() Vec3 {
    return vec3(rtweekend.randomDouble() - 0.5, rtweekend.randomDouble() - 0.5, 0);
}
