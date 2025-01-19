const std = @import("std");

pub fn ppmWriter(writer: anytype, width: usize, height: usize) anyerror!void {
    //const width = image.len;
    //const height = image[0].len;
    try writer.print("P3\n{d} {d}\n255\n", .{ width, height });
    {
        for (0..height) |j| {
            for (0..width) |i| {
                const r: f64 = @as(f64, @floatFromInt(i)) / @as(f64, @floatFromInt(width - 1));
                const g: f64 = @as(f64, @floatFromInt(j)) / @as(f64, @floatFromInt(height - 1));
                const b: f64 = 0.0;

                const ir = @as(u8, @intCast(@as(i64, @intFromFloat(255.999 * r))));
                const ig = @as(u8, @intCast(@as(i64, @intFromFloat(255.999 * g))));
                const ib = @as(u8, @intCast(@as(i64, @intFromFloat(255.999 * b))));

                try writer.print("{d} {d} {d}\n", .{ ir, ig, ib });
            }
        }
    }
}
