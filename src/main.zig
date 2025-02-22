const std = @import("std");
const math = std.math;
const vec = @import("vec.zig").vec3;
const Vec = @import("vec.zig").Vec3;
const HitTableList = @import("hittable_list.zig").HitTableList;
const camera = @import("camera.zig");
const sphere = @import("sphere.zig").sphere;
const sphereMoving = @import("sphere.zig").sphereMoving;
const Material = @import("material.zig").Material;
const Lambertian = @import("material.zig").Lambertian;
const Metal = @import("material.zig").Metal;
const Dielectric = @import("material.zig").Dielectric;
const rtweekend = @import("rtweekend.zig");
const randomDouble = @import("rtweekend.zig").randomDouble;
const randomDoubleMinMax = @import("rtweekend.zig").randomDoubleMinMax;
const BVHNode = @import("bvh.zig").BVHNode;
const texture = @import("texture.zig");
const rtwSTB = @import("rtw_stb_image.zig");

pub fn perlinSpheres() !void {
    const aspect_ratio = 16.0 / 9.0;
    const image_width: u32 = 400;
    const focal_length = 1.0;
    const viewport_height = 2.0;
    const camera_center = vec(0, 0, 0);
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = gpa.allocator();
    var world = HitTableList.init(allocator);

    defer world.deinit();
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const arena_allocator = arena.allocator();

    const perlin_texture = try texture.NoiseTexture.init(&allocator);

    const material_heap = try arena_allocator.create(Material);
    material_heap.* = Material{ .lambertian = Lambertian.initTexture(texture.Texture{ .noiseTexture = perlin_texture }) };

    const material_heap_2 = try arena_allocator.create(Material);
    material_heap_2.* = Material{ .lambertian = Lambertian.initTexture(texture.Texture{ .noiseTexture = perlin_texture }) };

    try world.add(.{ .sphere = sphere(vec(0, -1000, 0), 1000, material_heap) });
    try world.add(.{ .sphere = sphere(vec(0, 2, 0), 2, material_heap_2) });
    var bvh_root = try BVHNode.initFromList(&allocator, &world);

    var cam = camera.Camera.init(aspect_ratio, image_width, focal_length, viewport_height, camera_center);
    cam.samples_per_pixel = 100;
    cam.vfov = 20;
    cam.lookfrom = vec(13, 2, 3);
    cam.lookat = vec(0, 0, 0);
    cam.vup = vec(0, 1, 0);
    cam.defocus_angle = 0.0;
    cam.focus_dist = 10.0;
    try cam.render(&bvh_root, &allocator);
}

pub fn earth() !void {
    const aspect_ratio = 16.0 / 9.0;
    const image_width: u32 = 400;
    const focal_length = 1.0;
    const viewport_height = 2.0;
    const camera_center = vec(0, 0, 0);
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = gpa.allocator();

    var world = HitTableList.init(allocator);

    defer world.deinit();
    const earth_image = try allocator.create(rtwSTB.Image);
    earth_image.* = try rtwSTB.Image.init("earthmap.jpg", allocator);
    std.debug.print("Image dimensions: {}x{}\n", .{ earth_image.width, earth_image.height });

    const earth_texture = texture.ImageTexture.init(earth_image);
    const earth_surface = Material{ .lambertian = Lambertian.initTexture(texture.Texture{ .imageTexture = earth_texture }) };

    try world.add(.{ .sphere = sphere(vec(0, 0, 0), 2, &earth_surface) });

    // Free allocated resources when done
    //earth_image.deinit(allocator);
    //allocator.destroy(earth_image);
    var bvh_root = try BVHNode.initFromList(&allocator, &world);

    var cam = camera.Camera.init(aspect_ratio, image_width, focal_length, viewport_height, camera_center);
    cam.samples_per_pixel = 100;
    cam.vfov = 20;
    cam.lookfrom = vec(0, 0, 12);
    cam.lookat = vec(0, 0, 0);
    cam.vup = vec(0, 1, 0);
    cam.defocus_angle = 0.0;
    cam.focus_dist = 10.0;
    try cam.render(&bvh_root, &allocator);
}
pub fn bouncingSperes() !void {
    const aspect_ratio = 16.0 / 9.0;
    const image_width: u32 = 400;
    const focal_length = 1.0;
    const viewport_height = 2.0;
    const camera_center = vec(0, 0, 0);
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = gpa.allocator();

    var world = HitTableList.init(allocator);

    defer world.deinit();

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const arena_allocator = arena.allocator();

    var even = texture.Texture{ .solidColor = texture.SolidColor.init(vec(0.2, 0.3, 0.1)) };
    var odd = texture.Texture{ .solidColor = texture.SolidColor.init(vec(0.9, 0.9, 0.9)) };
    const checker = texture.CheckTexture.init(0.32, &even, &odd);
    const ground_material = Material{ .lambertian = Lambertian.initTexture(texture.Texture{ .checkTexture = checker }) };
    try world.add(.{ .sphere = sphere(vec(0, -1000, 0), 1000, &ground_material) });

    var a: i32 = -3;
    while (a < 3) : (a += 1) {
        var b: i32 = -3;
        while (b < 3) : (b += 1) {
            const choose_mat = randomDouble();
            const a_f = @as(f64, @floatFromInt(a));
            const b_f = @as(f64, @floatFromInt(b));
            const r_1 = randomDouble();
            const r_2 = randomDouble();

            const center = vec(a_f + 0.9 * r_1, 0.2, b_f + 0.9 * r_2);

            if ((center.sub(vec(4, 0.2, 0))).length() > 0.9) {
                const sphere_material = try arena_allocator.create(Material);
                if (choose_mat < 0.8) {
                    const albedo = Vec.random().mul(Vec.random());
                    sphere_material.* = .{ .lambertian = Lambertian.init(albedo) };
                    const center2 = center.add(vec(0, rtweekend.randomDoubleMinMax(0, 0.5), 0));
                    try world.add(.{ .sphere = sphereMoving(center, center2, 0.2, sphere_material) });
                } else if (choose_mat < 0.95) {
                    const albedo = Vec.randomMinMax(0.5, 1);
                    const fuzz = randomDoubleMinMax(0, 0.5);
                    sphere_material.* = .{ .metal = Metal.init(albedo, fuzz) };
                    try world.add(.{ .sphere = sphere(center, 0.2, sphere_material) });
                } else {
                    sphere_material.* = .{ .dielectric = Dielectric.init(1.5) };
                    try world.add(.{ .sphere = sphere(center, 0.2, sphere_material) });
                }
            }
        }
    }
    const material1 = Material{ .dielectric = Dielectric.init(1.50) };
    try world.add(.{ .sphere = sphere(vec(0, 1, 0), 1.0, &material1) });

    const material2 = Material{ .lambertian = Lambertian.init(vec(0.4, 0.2, 0.1)) };
    try world.add(.{ .sphere = sphere(vec(-4, 1, 0), 1.0, &material2) });

    const material3 = Material{ .metal = Metal.init(vec(0.7, 0.6, 0.5), 0.0) };
    try world.add(.{ .sphere = sphere(vec(4, 1, 0), 1.0, &material3) });

    var bvh_root = try BVHNode.initFromList(&allocator, &world);

    //try world.add(bvh_root.HitTable);
    var cam = camera.Camera.init(aspect_ratio, image_width, focal_length, viewport_height, camera_center);
    cam.samples_per_pixel = 100;
    cam.vfov = 20;
    cam.lookfrom = vec(13, 2, 3);
    cam.lookat = vec(0, 0, 0);
    cam.vup = vec(0, 1, 0);
    cam.defocus_angle = 0.6;
    cam.focus_dist = 10.0;
    try cam.render(&bvh_root, &allocator);
}
pub fn main() !void {
    try perlinSpheres();
}
