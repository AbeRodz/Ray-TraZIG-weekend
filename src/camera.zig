const std = @import("std");
const math = std.math;
const vec = @import("vec.zig");

pub const Viewport = struct {
    pixel_delta_u: vec.Vec3,
    pixel_delta_v: vec.Vec3,
    viewport_upper_left: vec.Vec3,
    pixel0_location: vec.Vec3,
};
pub const Camera = struct {
    image_width: u32,
    image_height: u32,
    focal_length: f64,
    viewport_height: f64,
    viewport_width: f64,
    camera_center: vec.Vec3,

    pub fn init(
        image_width: u32,
        image_height: u32,
        focal_length: f64,
        viewport_height: f64,
        viewport_width: f64,
        camera_center: vec.Vec3,
    ) Camera {
        return Camera{
            .image_width = image_width,
            .image_height = image_height,
            .focal_length = focal_length,
            .viewport_height = viewport_height,
            .viewport_width = viewport_width,
            .camera_center = camera_center,
        };
    }

    pub fn calculate_viewport(self: Camera) Viewport {
        var viewport_u = vec.Vec3.init(self.viewport_width, 0.0, 0.0);
        var viewport_v = vec.Vec3.init(0.0, -self.viewport_height, 0.0);

        const pixel_delta_u = viewport_u.scalarDivision(@as(f64, @floatFromInt(self.image_width)));
        const pixel_delta_v = viewport_v.scalarDivision(@as(f64, @floatFromInt(self.image_height)));

        const focal_vec = vec.Vec3.init(0, 0, self.focal_length);
        viewport_u = viewport_u.scalarMul(0.5);
        viewport_v = viewport_v.scalarMul(0.5);
        const viewport_u_v = viewport_u.sub(viewport_v);

        const viewport_upper_left = self.camera_center.sub(focal_vec.sub(viewport_u_v));

        const pixel_delta_sum = pixel_delta_u.add(pixel_delta_v);

        const pixel0_location = viewport_upper_left.add(pixel_delta_sum.scalarMul(0.5));
        return Viewport{
            .pixel_delta_u = pixel_delta_u,
            .pixel_delta_v = pixel_delta_v,
            .viewport_upper_left = viewport_upper_left,
            .pixel0_location = pixel0_location,
        };
    }
};
