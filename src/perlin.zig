const rtweekend = @import("rtweekend.zig");
const Vec3 = @import("vec.zig").Vec3;
const vec = @import("vec.zig").vec3;
const std = @import("std");
const math = std.math;

pub const Perlin = struct {
    point_count: u16 = 256,
    randfloat: [256]f64,
    randvec: [256]Vec3,
    perm_x: [256]u16,
    perm_y: [256]u16,
    perm_z: [256]u16,

    const Self = @This();

    pub fn init() Self {
        var perlin = Self{
            .randfloat = undefined,
            .randvec = undefined,
            .perm_x = undefined,
            .perm_y = undefined,
            .perm_z = undefined,
        };

        for (0..perlin.point_count) |i| {
            perlin.randvec[i] = Vec3.random().unitVector();
            //perlin.randfloat[i] = rtweekend.randomDouble();
        }

        perlin.perlinGeneratePerm(&perlin.perm_x);
        perlin.perlinGeneratePerm(&perlin.perm_y);
        perlin.perlinGeneratePerm(&perlin.perm_z);

        return perlin;
    }

    pub fn noise(self: Self, p: *const Vec3) f64 {
        const u = p.x() - math.floor(p.x());
        const v = p.y() - math.floor(p.y());
        const w = p.z() - math.floor(p.z());

        // u = u * u * (3 - 2 * u);
        // v = v * v * (3 - 2 * v);
        // w = w * w * (3 - 2 * w);

        const i = @as(u16, @intFromFloat(@floor(@abs(p.x()))));
        const j = @as(u16, @intFromFloat(@floor(@abs(p.y()))));
        const k = @as(u16, @intFromFloat(@floor(@abs(p.z()))));

        var c: [2][2][2]Vec3 = undefined;

        for (0..2) |di| {
            for (0..2) |dj| {
                for (0..2) |dk| {
                    const index =
                        (self.perm_x[(i + di) & 255] ^
                        self.perm_y[(j + dj) & 255] ^
                        self.perm_z[(k + dk) & 255]);

                    c[di][dj][dk] = self.randvec[index];
                }
            }
        }
        return perlinInterpolation(c, u, v, w);
    }
    pub fn turb(self: Self, p: *const Vec3, depth: u16) f64 {
        var accum: f64 = 0.0;
        var temp_p = p;
        var weight: f64 = 1.0;

        for (0..depth) |_| {
            accum += weight * self.noise(temp_p);
            weight *= 0.5;
            temp_p = &temp_p.*.scalarMul(2);
        }

        return @abs(accum);
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
    inline fn trilinearInterpolation(c: [2][2][2]f64, u: f64, v: f64, w: f64) f64 {
        var accum: f64 = 0.0;
        for (0..2) |i| {
            const ii = @as(f64, (@floatFromInt(i)));
            for (0..2) |j| {
                const jj = @as(f64, (@floatFromInt(j)));
                for (0..2) |k| {
                    const kk = @as(f64, (@floatFromInt(k)));
                    accum += (ii * u + (1 - ii) * (1 - u)) * (jj * v + (1 - jj) * (1 - v)) * (kk * w + (1 - kk) * (1 - w)) * c[i][j][k];
                }
            }
        }
        return accum;
    }

    inline fn perlinInterpolation(c: [2][2][2]Vec3, u: f64, v: f64, w: f64) f64 {
        const uu = u * u * (3 - 2 * u);
        const vv = v * v * (3 - 2 * v);
        const ww = w * w * (3 - 2 * w);
        var accum: f64 = 0.0;

        for (0..2) |i| {
            const ii = @as(f64, (@floatFromInt(i)));
            for (0..2) |j| {
                const jj = @as(f64, (@floatFromInt(j)));
                for (0..2) |k| {
                    const kk = @as(f64, (@floatFromInt(k)));
                    const weight_v = vec(u - ii, v - jj, w - kk);
                    accum += (ii * uu + (1 - ii) * (1 - uu)) * (jj * vv + (1 - jj) * (1 - vv)) * (kk * ww + (1 - kk) * (1 - ww)) * c[i][j][k].dot(weight_v);
                }
            }
        }

        return accum;
    }
};
