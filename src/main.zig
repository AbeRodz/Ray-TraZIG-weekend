const std = @import("std");
const vec = @import("vec.zig").vec3;
const Vec = @import("vec.zig").Vec3;
const HitTableList = @import("hittable_list.zig").HitTableList;
const camera = @import("camera.zig");
const sphere = @import("sphere.zig").sphere;
const Quad = @import("quad.zig").Quad;
const sphereMoving = @import("sphere.zig").sphereMoving;
const Material = @import("material.zig").Material;
const Lambertian = @import("material.zig").Lambertian;
const Metal = @import("material.zig").Metal;
const Dielectric = @import("material.zig").Dielectric;
const DiffuseLight = @import("material.zig").DiffuseLight;
const rtweekend = @import("rtweekend.zig");
const randomDouble = @import("rtweekend.zig").randomDouble;
const randomDoubleMinMax = @import("rtweekend.zig").randomDoubleMinMax;
const BVHNode = @import("bvh.zig").BVHNode;
const texture = @import("texture.zig");
const rtwSTB = @import("rtw_stb_image.zig");

pub fn perlinSpheres(allocator: *std.mem.Allocator, arena_allocator: *std.mem.Allocator, world: *HitTableList) !void {
    const perlin_texture = try texture.NoiseTexture.init(&allocator, 4);

    const material_heap = try arena_allocator.create(Material);
    material_heap.* = Material{ .lambertian = Lambertian.initTexture(texture.Texture{ .noiseTexture = perlin_texture }) };

    const material_heap_2 = try arena_allocator.create(Material);
    material_heap_2.* = Material{ .lambertian = Lambertian.initTexture(texture.Texture{ .noiseTexture = perlin_texture }) };

    try world.add(.{ .sphere = sphere(vec(0, -1000, 0), 1000, material_heap) });
    try world.add(.{ .sphere = sphere(vec(0, 2, 0), 2, material_heap_2) });
    var bvh_root = try BVHNode.initFromList(allocator, world);

    var cam = camera.Camera.baseCameraInit();
    cam.lookfrom = vec(13, 2, 3);
    cam.lookat = vec(0, 0, 0);
    cam.vup = vec(0, 1, 0);
    try cam.render(&bvh_root, allocator);
}

pub fn earth(allocator: *std.mem.Allocator, world: *HitTableList) !void {
    const earth_image = try allocator.create(rtwSTB.Image);
    earth_image.* = try rtwSTB.Image.init("earthmap.jpg", allocator.*);

    const earth_texture = texture.ImageTexture.init(earth_image);
    const earth_surface = Material{ .lambertian = Lambertian.initTexture(texture.Texture{ .imageTexture = earth_texture }) };

    try world.add(.{ .sphere = sphere(vec(0, 0, 0), 2, &earth_surface) });

    var bvh_root = try BVHNode.initFromList(allocator, world);

    var cam = camera.Camera.baseCameraInit();
    cam.samples_per_pixel = 100;
    cam.vfov = 20;
    cam.lookfrom = vec(0, 0, 12);
    cam.lookat = vec(0, 0, 0);
    cam.vup = vec(0, 1, 0);
    cam.defocus_angle = 0.0;
    cam.focus_dist = 10.0;
    try cam.render(&bvh_root, allocator);
}
pub fn bouncingSperes(allocator: *std.mem.Allocator, arena_allocator: *std.mem.Allocator, world: *HitTableList) !void {
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

    var bvh_root = try BVHNode.initFromList(allocator, world);

    var cam = camera.Camera.baseCameraInit();
    cam.background = vec(0.70, 0.80, 1.00);
    cam.lookfrom = vec(13, 2, 3);
    cam.lookat = vec(0, 0, 0);
    cam.vup = vec(0, 1, 0);
    cam.defocus_angle = 0.6;
    try cam.render(&bvh_root, allocator);
}

pub fn simpleLight(allocator: *std.mem.Allocator, arena_allocator: *std.mem.Allocator, world: *HitTableList) !void {
    const perlin_texture = try texture.NoiseTexture.init(allocator, 4);

    const material_heap = try arena_allocator.create(Material);
    material_heap.* = Material{ .lambertian = Lambertian.initTexture(texture.Texture{ .noiseTexture = perlin_texture }) };

    const material_heap_2 = try arena_allocator.create(Material);
    material_heap_2.* = Material{ .lambertian = Lambertian.initTexture(texture.Texture{ .noiseTexture = perlin_texture }) };

    const light_texture = DiffuseLight.initColor(vec(4, 4, 4));
    const light_heap = try arena_allocator.create(Material);
    light_heap.* = Material{ .diffuseLight = light_texture };

    try world.add(.{ .sphere = sphere(vec(0, -1000, 0), 1000, material_heap) });
    try world.add(.{ .sphere = sphere(vec(0, 3, 0), 2, material_heap_2) });
    try world.add(.{ .quad = Quad.init(vec(3, 1, -2), vec(2, 0, 0), vec(0, 2, 0), light_heap) });
    try world.add(.{ .sphere = sphere(vec(0, 7, 0), 2, light_heap) });
    var bvh_root = try BVHNode.initFromList(allocator, world);

    var cam = camera.Camera.baseCameraInit();
    cam.vfov = 20;
    cam.background = vec(0, 0, 0);
    cam.lookfrom = vec(26, 3, 6);
    cam.lookat = vec(0, 2, 0);
    cam.vup = vec(0, 1, 0);

    try cam.render(&bvh_root, allocator);
}
pub fn quads(allocator: *std.mem.Allocator, arena_allocator: *std.mem.Allocator, world: *HitTableList) !void {
    const left_red = texture.Texture{ .solidColor = texture.SolidColor.init(vec(1.0, 0.2, 0.2)) };
    const back_green = texture.Texture{ .solidColor = texture.SolidColor.init(vec(0.2, 1.0, 0.2)) };
    const right_blue = texture.Texture{ .solidColor = texture.SolidColor.init(vec(0.2, 0.2, 1.0)) };
    const upper_orange = texture.Texture{ .solidColor = texture.SolidColor.init(vec(1.0, 0.5, 0.0)) };
    const lower_teal = texture.Texture{ .solidColor = texture.SolidColor.init(vec(0.2, 0.8, 0.8)) };

    const left_red_material = try arena_allocator.create(Material);

    const back_green_material = try arena_allocator.create(Material);
    const right_blue_material = try arena_allocator.create(Material);
    const lower_teal_material = try arena_allocator.create(Material);
    const upper_orange_material = try arena_allocator.create(Material);
    left_red_material.* = Material{ .lambertian = Lambertian.initTexture(left_red) };
    back_green_material.* = Material{ .lambertian = Lambertian.initTexture(back_green) };
    right_blue_material.* = Material{ .lambertian = Lambertian.initTexture(right_blue) };
    upper_orange_material.* = Material{ .lambertian = Lambertian.initTexture(upper_orange) };
    lower_teal_material.* = Material{ .lambertian = Lambertian.initTexture(lower_teal) };

    try world.add(.{ .quad = Quad.init(vec(-3, -2, 5), vec(0, 0, -4), vec(0, 4, 0), left_red_material) });
    try world.add(.{ .quad = Quad.init(vec(-2, -2, 0), vec(4, 0, 0), vec(0, 4, 0), back_green_material) });
    try world.add(.{ .quad = Quad.init(vec(3, -2, 1), vec(0, 0, 4), vec(0, 4, 0), right_blue_material) });
    try world.add(.{ .quad = Quad.init(vec(-2, 3, 1), vec(4, 0, 0), vec(0, 0, 4), upper_orange_material) });
    try world.add(.{ .quad = Quad.init(vec(-2, -3, 5), vec(4, 0, 0), vec(0, 0, -4), lower_teal_material) });

    var bvh_root = try BVHNode.initFromList(allocator, world);

    var cam = camera.Camera.baseCameraInit();
    cam.vfov = 80;
    cam.lookfrom = vec(0, 0, 9);
    cam.lookat = vec(0, 0, 0);
    cam.vup = vec(0, 1, 0);
    cam.background = vec(0.70, 0.80, 1.00);
    try cam.render(&bvh_root, allocator);
}

pub fn cornellBox(allocator: *std.mem.Allocator, arena_allocator: *std.mem.Allocator, world: *HitTableList) !void {
    const red = texture.Texture{ .solidColor = texture.SolidColor.init(vec(0.65, 0.05, 0.05)) };
    const white = texture.Texture{ .solidColor = texture.SolidColor.init(vec(0.73, 0.73, 0.73)) };
    const green = texture.Texture{ .solidColor = texture.SolidColor.init(vec(0.12, 0.45, 0.15)) };

    const light_texture = DiffuseLight.initColor(vec(15, 15, 15));
    const light_heap = try arena_allocator.create(Material);
    light_heap.* = Material{ .diffuseLight = light_texture };

    const red_material = try arena_allocator.create(Material);
    const white_material = try arena_allocator.create(Material);
    const green_material = try arena_allocator.create(Material);

    red_material.* = Material{ .lambertian = Lambertian.initTexture(red) };
    white_material.* = Material{ .lambertian = Lambertian.initTexture(white) };
    green_material.* = Material{ .lambertian = Lambertian.initTexture(green) };

    try world.add(.{ .quad = Quad.init(vec(555, 0, 0), vec(0, 555, 0), vec(0, 0, 555), green_material) });
    try world.add(.{ .quad = Quad.init(vec(0, 0, 0), vec(0, 555, 0), vec(0, 0, 555), red_material) });
    try world.add(.{ .quad = Quad.init(vec(343, 554, 332), vec(-130, 0, 0), vec(0, 0, -105), light_heap) });
    try world.add(.{ .quad = Quad.init(vec(0, 0, 0), vec(555, 0, 0), vec(0, 0, 555), white_material) });
    try world.add(.{ .quad = Quad.init(vec(555, 555, 555), vec(-555, 0, 0), vec(0, 0, -555), white_material) });
    try world.add(.{ .quad = Quad.init(vec(0, 0, 555), vec(555, 0, 0), vec(0, 555, 0), white_material) });

    var bvh_root = try BVHNode.initFromList(allocator, world);

    var cam = camera.Camera.baseCameraInit();
    cam.aspect_ratio = 1.0;
    cam.image_width = 600;
    cam.samples_per_pixel = 50;
    cam.max_depth = 10;
    cam.vfov = 40;
    cam.lookfrom = vec(278, 278, -800);
    cam.lookat = vec(278, 278, 0);
    cam.vup = vec(0, 1, 0);
    cam.background = vec(0, 0, 0);
    cam.defocus_angle = 0;
    try cam.render(&bvh_root, allocator);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = gpa.allocator();
    var world = HitTableList.init(allocator);

    defer world.deinit();
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    var arena_allocator = arena.allocator();

    try simpleLight(&allocator, &arena_allocator, &world);
}
