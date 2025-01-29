const std = @import("std");
const math = std.math;
const vec = @import("vec.zig");
const color = @import("color.zig");
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
    max_depth: u32 = 50,
    vfov: f64 = 90,
    lookfrom: Vec3 = vec3(0, 0, 0), // Point camera is looking from
    lookat: Vec3 = vec3(0, 0, -1), // Point camera is looking at
    vup: Vec3 = vec3(0, 1, 0),
    defocus_angle: f64 = 0, // Variation angle of rays through each pixel
    focus_dist: f64 = 10,
    defocus_disk_u: Vec3,
    defocus_disk_v: Vec3,
    v: Vec3,
    u: Vec3,
    w: Vec3,

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
            .v = undefined,
            .w = undefined,
            .u = undefined,
            .defocus_disk_u = undefined,
            .defocus_disk_v = undefined,
        };
    }
    pub fn initialize(self: *Self) void {
        self.image_height = @as(u32, @intFromFloat(@as(f32, @floatFromInt(self.image_width)) / self.aspect_ratio));
        self.image_height = if (self.image_height < 1) 1 else self.image_height;

        self.camera_center = self.lookfrom;

        const theta = rtweekend.degreesToRadians(self.vfov);
        const h: f64 = math.tan(theta / 2);

        self.viewport_height = 2 * h * self.focus_dist;
        const viewport_width = self.viewport_height * (@as(f64, @floatFromInt(self.image_width)) / @as(f64, @floatFromInt(self.image_height)));

        self.w = self.lookfrom.sub(self.lookat).unitVector();
        self.u = self.vup.cross(self.w).unitVector();
        self.v = self.w.cross(self.u);

        // Calculate the vectors across the horizontal and down the vertical viewport edges.
        const viewport_u = self.u.scalarMul(viewport_width); // Vector across viewport horizontal edge
        const viewport_v = self.v.negative().scalarMul(self.viewport_height);
        self.pixel_delta_u = viewport_u.scalarDivision(@floatFromInt(self.image_width));
        self.pixel_delta_v = viewport_v.scalarDivision(@floatFromInt(self.image_height));

        const viewport_upper_left = self.camera_center.sub(self.w.scalarMul(self.focus_dist)).sub(viewport_u.scalarDivision(2)).sub(viewport_v.scalarDivision(2));
        const defocus_radius = self.focus_dist * math.tan(rtweekend.degreesToRadians(self.defocus_angle / 2));
        self.defocus_disk_u = self.u.scalarMul(defocus_radius);
        self.defocus_disk_v = self.v.scalarMul(defocus_radius);
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
            var scattered: Ray = undefined;
            var attenuation: Vec3 = undefined;
            if (hit_record.material.scatter(r, hit_record, &attenuation, &scattered))
                return attenuation.mul(rayColor(scattered, depth - 1, world));
            return vec3(0, 0, 0);
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
        const ray_origin = if (self.defocus_angle <= 0) self.camera_center else self.defocus_disk_sample();
        const ray_direction = pixel_sample.sub(ray_origin);
        return ray(ray_origin, ray_direction);
    }
    fn defocus_disk_sample(self: Self) Vec3 {
        // Returns a random point in the camera defocus disk.
        const p = Vec3.randomInUnitDisk();
        return self.camera_center.add(self.defocus_disk_u.scalarMul(p.x)).add(self.defocus_disk_v.scalarMul(p.y));
    }
};

fn sampleSquare() Vec3 {
    return vec3(rtweekend.randomDouble() - 0.5, rtweekend.randomDouble() - 0.5, 0);
}
