const std = @import("std");
const ppm = @import("ppm.zig");
const Vec3 = @import("vec.zig").Vec3;
const vec = @import("vec.zig").vec3;

const ray = @import("ray.zig");
const camera = @import("camera.zig");

pub fn main() !void {
    const aspect_ratio = 16.0 / 9.0;
    const image_width: u32 = 400;

    var image_height: u32 = @as(f32, @floatFromInt(image_width)) / aspect_ratio;
    image_height = if (image_height < 1) 1 else image_height;

    const focal_length = 1.0;
    const viewport_height = 2.0;
    const viewport_width = viewport_height * (@as(f64, @floatFromInt(image_width)) / @as(f64, @floatFromInt(image_height)));

    const camera_center = vec(0, 0, 0);

    const viewport_u = vec(viewport_width, 0, 0);
    const viewport_v = vec(0, -viewport_height, 0);
    const pixel_delta_u = viewport_u.scalarDivision(image_width);
    const pixel_delta_v = viewport_v.scalarDivision(@floatFromInt(image_height));

    const viewport_upper_left = camera_center.sub(vec(0, 0, focal_length)).sub(viewport_u.scalarDivision(2)).sub(viewport_v.scalarDivision(2));
    const pixel00_loc = viewport_upper_left.add(pixel_delta_u.add(pixel_delta_v).scalarMul(0.5));

    var buffered_writer = std.io.bufferedWriter(std.io.getStdOut().writer());
    const writer = buffered_writer.writer();

    try ppm.ppmWriter(&writer, image_width, image_height, pixel_delta_u, pixel_delta_v, pixel00_loc, camera_center);
    try buffered_writer.flush();
    std.debug.print("PPM file generated successfully.\n", .{});
}
