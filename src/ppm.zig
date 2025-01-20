const std = @import("std");
const color = @import("color.zig");
const vec3 = @import("vec.zig");

pub fn ppmWriter(writer: anytype, width: usize, height: usize) anyerror!void {
    //const width = image.len;
    //const height = image[0].len;
    try writer.print("P3\n{d} {d}\n255\n", .{ width, height });
    {
        for (0..height) |j| {
            for (0..width) |i| {
                const pixel_color = vec3.Vec3.init(@as(f64, @floatFromInt(i)) / @as(f64, @floatFromInt(width - 1)), @as(f64, @floatFromInt(j)) / @as(f64, @floatFromInt((height - 1))), 0.0);
                try color.write_color(writer, pixel_color);
            }
        }
    }
}
