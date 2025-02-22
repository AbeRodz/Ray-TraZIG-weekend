const std = @import("std");
const math = std.math;
const vec = @import("vec.zig");
const color = @import("color.zig");
const Vec3 = @import("vec.zig").Vec3;
const vec3 = @import("vec.zig").vec3;
const Ray = @import("ray.zig").Ray;
const ray = @import("ray.zig").ray;
const HitTableList = @import("hittable_list.zig").HitTableList;
const BVHNode = @import("bvh.zig").BVHNode;
const HitRecord = @import("hittable.zig").HitRecord;
const interval = @import("interval.zig").interval;
const rtweekend = @import("rtweekend.zig");
const Thread = std.Thread;
const Allocator = std.mem.Allocator;
const time = std.time;
const Instant = time.Instant;
const Timer = time.Timer;

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
    fn renderSection(
        camera: *Camera,
        world: BVHNode,
        start_row: u32,
        end_row: u32,
        output: []Vec3,
    ) void {
        for (start_row..end_row) |j| {
            for (0..camera.image_width) |i| {
                var pixel_color = vec3(0, 0, 0);
                const i_f = @as(f64, @floatFromInt(i));
                const j_f = @as(f64, @floatFromInt(j));
                for (0..camera.samples_per_pixel) |_| {
                    const r = camera.getRay(i_f, j_f);
                    pixel_color = pixel_color.add(rayColor(r, camera.max_depth, world));
                }
                output[(j - start_row) * camera.image_width + i] = pixel_color;
            }
        }
    }
    pub fn threadedRender(self: *Self, allocator: *Allocator, world: *BVHNode) !void {
        self.initialize();
        const num_threads = try Thread.getCpuCount();

        var threads = try allocator.alloc(Thread, num_threads);
        defer allocator.free(threads);

        const outputs = try allocator.alloc([]Vec3, num_threads);
        defer allocator.free(outputs);
        const threadConfig = Thread.SpawnConfig{
            .stack_size = 1024 * 16,
        };
        for (0..num_threads) |i| {
            threads[i] = try Thread.spawn(threadConfig, render, .{ self, world, allocator });
        }

        for (threads) |t| {
            t.join();
        }
    }

    pub fn render(self: *Self, world: *BVHNode, allocator: *Allocator) !void {
        self.initialize();

        var buffered_writer = std.io.bufferedWriter(std.io.getStdOut().writer());
        const writer = buffered_writer.writer();
        try writer.print("P3\n{d} {d}\n255\n", .{ self.image_width, self.image_height });

        const num_threads = try Thread.getCpuCount();

        var threads = try allocator.alloc(Thread, num_threads);
        defer allocator.free(threads);

        const outputs = try allocator.alloc([]Vec3, num_threads);
        defer allocator.free(outputs);

        const rows_per_thread: u32 = self.image_height / @as(u32, @intCast(num_threads));
        const extra_rows: u32 = self.image_height % @as(u32, @intCast(num_threads));

        std.debug.print("rows per thread: {}\n", .{rows_per_thread});

        for (0..num_threads) |t| {
            const is_last_thread = t == num_threads - 1;
            const actual_rows = rows_per_thread + if (is_last_thread) extra_rows else 0;
            outputs[t] = try allocator.alloc(Vec3, self.image_width * actual_rows);
        }

        const threadConfig = Thread.SpawnConfig{
            .stack_size = 1024 * 16,
        };

        // Spawn threads
        const start = try Instant.now();
        for (0..num_threads) |t| {
            const start_row = @as(u32, @intCast(t)) * rows_per_thread;
            const end_row = if (t == num_threads - 1) self.image_height else start_row + rows_per_thread;
            threads[t] = try Thread.spawn(threadConfig, renderSection, .{ self, world.*, start_row, end_row, outputs[t] });
        }

        std.debug.print("", .{});
        for (0..num_threads) |t| {
            threads[t].join();
        }
        const end = try Instant.now();

        const elapsed1: f64 = @floatFromInt(end.since(start));
        std.debug.print("Time elapsed is: {d:.3}ms\n", .{
            elapsed1 / time.ns_per_ms,
        });

        for (0..num_threads) |t| {
            const is_last_thread = t == num_threads - 1;
            const actual_rows = rows_per_thread + if (is_last_thread) extra_rows else 0;

            for (0..actual_rows) |j| {
                for (0..self.image_width) |i| {
                    try color.write_color(writer, outputs[t][j * self.image_width + i], self.samples_per_pixel);
                }
            }
        }

        try buffered_writer.flush();
        std.debug.print("PPM file generated successfully.\n", .{});

        for (0..num_threads) |t| {
            allocator.free(outputs[t]);
        }
    }

    fn rayColor(r: Ray, depth: u32, world: BVHNode) Vec3 {
        var current_ray = r;
        var current_depth = depth;
        var colorVec = vec3(1, 1, 1); // Accumulator for attenuation

        while (current_depth > 0) {
            var hit_record: HitRecord = undefined;
            if (world.hit(current_ray, interval(0.001, rtweekend.infinity), &hit_record)) {
                var scattered: Ray = undefined;
                var attenuation: Vec3 = undefined;
                if (!hit_record.material.scatter(current_ray, hit_record, &attenuation, &scattered)) {
                    return vec3(0, 0, 0);
                }
                colorVec = colorVec.mul(attenuation);
                current_ray = scattered;
            } else {
                const unit_direction = current_ray.direction.unitVector();
                const a = 0.5 * (unit_direction.y() + 1.0);
                return colorVec.mul(vec3(1, 1, 1).scalarMul(1.0 - a).add(vec3(0.5, 0.7, 1.0).scalarMul(a)));
            }
            current_depth -= 1;
        }
        return vec3(0, 0, 0);
    }

    inline fn getRay(self: Self, i: f64, j: f64) Ray {
        const offset = sampleSquare();

        const pixel_sample = self.pixel00_loc.add(self.pixel_delta_u.scalarMul((offset.x() + i)).add(self.pixel_delta_v.scalarMul((offset.y() + j))));
        const ray_origin = if (self.defocus_angle <= 0) self.camera_center else self.defocus_disk_sample();
        const ray_direction = pixel_sample.sub(ray_origin);
        const ray_time = rtweekend.randomDouble();
        return ray(ray_origin, ray_direction, ray_time);
    }
    fn defocus_disk_sample(self: Self) Vec3 {
        // Returns a random point in the camera defocus disk.
        const p = Vec3.randomInUnitDisk();
        return self.camera_center.add(self.defocus_disk_u.scalarMul(p.x())).add(self.defocus_disk_v.scalarMul(p.y()));
    }
};

inline fn sampleSquare() Vec3 {
    return vec3(rtweekend.randomDouble() - 0.5, rtweekend.randomDouble() - 0.5, 0);
}
