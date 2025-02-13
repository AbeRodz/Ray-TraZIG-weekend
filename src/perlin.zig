const rtweekend = @import("rtweekend.zig");
const Vec3 = @import("vec.zig").Vec3;
const std = @import("std");
pub const Perlin = struct {
    point_count: u16 = 256,
    randfloat: [256]f64,
    perm_x: [256]u16,
    perm_y: [256]u16,
    perm_z: [256]u16,

    const Self = @This();

    pub fn init() Self {
        var perlin = Self{
            .randfloat = undefined,
            .perm_x = undefined,
            .perm_y = undefined,
            .perm_z = undefined,
        };

        for (0..perlin.point_count) |i| {
            perlin.randfloat[i] = rtweekend.randomDouble();
        }

        perlin.perlinGeneratePerm(&perlin.perm_x);
        perlin.perlinGeneratePerm(&perlin.perm_y);
        perlin.perlinGeneratePerm(&perlin.perm_z);

        return perlin;
    }

    pub fn noise(self: Self, p: *const Vec3) f64 {
        const i = @as(u16, @intFromFloat(4 * @abs(p.x()))) & 255;
        const j = @as(u16, @intFromFloat(4 * @abs(p.y()))) & 255;
        const k = @as(u16, @intFromFloat(4 * @abs(p.z()))) & 255;

        const index = (self.perm_x[i] ^ self.perm_y[j] ^ self.perm_z[k]) % 255;
        return self.randfloat[index];
    }

    fn perlinGeneratePerm(self: Self, p: *[256]u16) void {
        for (0..self.point_count) |i| {
            p[i] = @as(u16, @intCast(i));
        }

        permute(p, self.point_count);
    }
    fn permute(p: *[256]u16, n: u16) void {
        var i = n - 1;
        while (i > 0) : (i -= 1) {
            const target = rtweekend.randomInt16(0, i);
            const tmp = p[i];
            p[i] = p[target];
            p[target] = tmp;
        }
    }
};
