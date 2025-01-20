const std = @import("std");
const vec = @import("vec.zig");

pub fn write_color(writer: anytype, pixel_color: vec.Vec3) anyerror!void {
    const r = pixel_color.x;
    const g = pixel_color.y;
    const b = pixel_color.z;

    const r_byte = @as(u8, @intCast(@as(i64, @intFromFloat(255.999 * r))));
    const g_byte = @as(u8, @intCast(@as(i64, @intFromFloat(255.999 * g))));
    const b_byte = @as(u8, @intCast(@as(i64, @intFromFloat(255.999 * b))));

    try writer.print("{d} {d} {d}\n", .{ r_byte, g_byte, b_byte });
}
