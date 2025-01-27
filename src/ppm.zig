const std = @import("std");
const math = std.math;
const color = @import("color.zig");
const Vec3 = @import("vec.zig").Vec3;
const vec3 = @import("vec.zig").vec3;
const camera = @import("camera.zig");
const ray = @import("ray.zig");
const sphere = @import("sphere.zig").sphere;
const HitRecord = @import("hittable.zig").HitRecord;
const HitTable = @import("hittable.zig").HitTable;
const HitTableList = @import("hittable_list.zig").HitTableList;
const rtweekend = @import("rtweekend.zig");

pub fn ppmWriter(writer: anytype, width: u32, height: u32, pixel_delta_u: Vec3, pixel_delta_v: Vec3, pixel00_loc: Vec3, camera_center: Vec3, world: *HitTableList) anyerror!void {
    try writer.print("P3\n{d} {d}\n255\n", .{ width, height });
    {
        for (0..height) |j| {
            for (0..width) |i| {
                const i_f = @as(f64, @floatFromInt(i));
                const j_f = @as(f64, @floatFromInt(j));

                const pixel_center = pixel00_loc.add(pixel_delta_u.scalarMul(i_f)).add(pixel_delta_v.scalarMul(j_f));
                const ray_direction = pixel_center.sub(camera_center);
                const rayVec = ray.Ray.init(camera_center, ray_direction);
                const pixel_color = rayColor(rayVec, world);

                try color.write_color(writer, pixel_color);
            }
        }
    }
}
pub fn rayColor(r: ray.Ray, world: *HitTableList) Vec3 {
    var hit_record: HitRecord = undefined;
    if (world.hit(r, 0, rtweekend.infinity, &hit_record)) {
        return hit_record.normal.add(vec3(1, 1, 1)).scalarMul(0.5);
    }
    const unit_direction = r.direction.unitVector();
    const a = 0.5 * (unit_direction.y + 1.0);
    return vec3(1, 1, 1).scalarMul(1.0 - a).add(vec3(0.5, 0.7, 1.0).scalarMul(a));
}
