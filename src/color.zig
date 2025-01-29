const std = @import("std");
const math = std.math;
const vec = @import("vec.zig");
const interval = @import("interval.zig").interval;

pub fn linear_to_gamm(linear_component: f64) f64 {
    if (linear_component > 0.0) {
        return math.sqrt(linear_component);
    }
    return 0;
}

pub fn write_color(writer: anytype, pixel_color: vec.Vec3, samples_per_pixel: u32) anyerror!void {
    var r = pixel_color.x();
    var g = pixel_color.y();
    var b = pixel_color.z();

    const scale = 1.0 / @as(f64, @floatFromInt(samples_per_pixel));
    r *= scale;
    g *= scale;
    b *= scale;

    r = linear_to_gamm(r);
    g = linear_to_gamm(g);
    b = linear_to_gamm(b);
    const intensity = interval(0.000, 0.999);

    const r_byte = @as(u32, @intCast(@as(i64, @intFromFloat(intensity.clamp(r) * 256))));
    const g_byte = @as(u32, @intCast(@as(i64, @intFromFloat(intensity.clamp(g) * 256))));
    const b_byte = @as(u32, @intCast(@as(i64, @intFromFloat(intensity.clamp(b) * 256))));

    try writer.print("{d} {d} {d}\n", .{ r_byte, g_byte, b_byte });
}
