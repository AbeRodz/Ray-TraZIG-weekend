const std = @import("std");
const vec = @import("vec.zig").vec3;
const HitTableList = @import("hittable_list.zig").HitTableList;
const camera = @import("camera.zig");
const sphere = @import("sphere.zig").sphere;
const Material = @import("material.zig").Material;
const Lambertian = @import("material.zig").Lambertian;
const Metal = @import("material.zig").Metal;

pub fn main() !void {
    const aspect_ratio = 16.0 / 9.0;
    const image_width: u32 = 400;
    const focal_length = 1.0;
    const viewport_height = 2.0;
    const camera_center = vec(0, 0, 0);
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var world = HitTableList.init(allocator);
    defer world.deinit();

    const material_ground = Material{ .lambertian = Lambertian.init(vec(0.8, 0.8, 0.0)) };
    const material_center = Material{ .lambertian = Lambertian.init(vec(0.1, 0.2, 0.5)) };
    const material_left = Material{ .metal = Metal.init(vec(0.8, 0.8, 0.8), 0.3) };
    const material_right = Material{ .metal = Metal.init(vec(0.8, 0.6, 0.2), 1.0) };
    try world.add(.{ .sphere = sphere(vec(0, -100.5, -1), 100, &material_ground) });
    try world.add(.{ .sphere = sphere(vec(0, 0, -1), 0.5, &material_center) });
    try world.add(.{ .sphere = sphere(vec(-1, 0, -1), 0.5, &material_left) });
    try world.add(.{ .sphere = sphere(vec(1, 0, -1), 0.5, &material_right) });

    var cam = camera.Camera.init(aspect_ratio, image_width, focal_length, viewport_height, camera_center);
    cam.samples_per_pixel = 100;
    try cam.render(world);
}
