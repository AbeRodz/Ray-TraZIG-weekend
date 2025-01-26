const std = @import("std");
const math = std.math;
const color = @import("color.zig");
const Vec3 = @import("vec.zig").Vec3;
const vec3 = @import("vec.zig").vec3;
const camera = @import("camera.zig");
const ray = @import("ray.zig");
const sphere = @import("sphere.zig");

pub fn ppmWriter(writer: anytype, width: u32, height: u32, pixel_delta_u: Vec3, pixel_delta_v: Vec3, pixel00_loc: Vec3, camera_center: Vec3) anyerror!void {
    try writer.print("P3\n{d} {d}\n255\n", .{ width, height });
    {
        for (0..height) |j| {
            for (0..width) |i| {
                const i_f = @as(f64, @floatFromInt(i));
                const j_f = @as(f64, @floatFromInt(j));

                const pixel_center = pixel00_loc.add(pixel_delta_u.scalarMul(i_f)).add(pixel_delta_v.scalarMul(j_f));
                const ray_direction = pixel_center.sub(camera_center);
                const rayVec = ray.Ray.init(camera_center, ray_direction);
                const pixel_color = rayColor(rayVec);

                try color.write_color(writer, pixel_color);
            }
        }
    }
}
pub fn rayColor(r: ray.Ray) Vec3 {
    const t = sphere.hitSphere(vec3(0, 0, -1), 0.5, r);
    if (t > 0.0) {
        const normal = r.at(t).sub(vec3(0, 0, -1)).unitVector();
        return vec3(normal.x + 1, normal.y + 1, normal.z + 1).scalarMul(0.5);
    }
    const unit_direction = r.direction.unitVector();
    const a = 0.5 * (unit_direction.y + 1.0);
    return vec3(1, 1, 1).scalarMul(1.0 - a).add(vec3(0.5, 0.7, 1.0).scalarMul(a));
}
