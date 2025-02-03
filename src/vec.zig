const std = @import("std");
const math = std.math;
const rtweekend = @import("rtweekend.zig");

pub const Vec3 = struct {
    v: @Vector(3, f64),

    const Self = @This();

    /// Constructor
    pub inline fn init(x_x: f64, y_y: f64, z_z: f64) Self {
        return .{ .v = @Vector(3, f64){ x_x, y_y, z_z } };
    }

    /// Accessors for x, y, z components
    pub inline fn x(self: Self) f64 {
        return self.v[0];
    }

    pub inline fn y(self: Self) f64 {
        return self.v[1];
    }

    pub inline fn z(self: Self) f64 {
        return self.v[2];
    }

    /// Length squared
    pub inline fn lengthSquared(self: Self) f64 {
        const prod = self.v * self.v;
        return prod[0] + prod[1] + prod[2];
    }

    /// Length (magnitude)
    pub inline fn length(self: Self) f64 {
        return std.math.sqrt(self.lengthSquared());
    }

    /// Normalize (unit vector)
    pub inline fn unitVector(self: Self) Self {
        const len = self.length();
        if (len == 0) @panic("Cannot normalize a zero vector");
        return self.scalarMul(1.0 / len);
    }

    /// Vector addition (SIMD optimized)
    pub inline fn add(self: Self, other: Self) Self {
        return .{ .v = self.v + other.v };
    }

    /// Vector subtraction (SIMD optimized)
    pub inline fn sub(self: Self, other: Self) Self {
        return .{ .v = self.v - other.v };
    }

    /// Multiply component-wise (SIMD)
    pub inline fn mul(self: Self, other: Self) Self {
        return .{ .v = self.v * other.v };
    }

    /// Multiply by scalar (SIMD)
    pub inline fn scalarMul(self: Self, scalar: f64) Self {
        return .{ .v = self.v * @as(@Vector(3, f64), @splat(scalar)) };
    }

    pub fn scalarDivision(self: Self, scalar: f64) Self {
        return .{ .v = self.v / @as(@Vector(3, f64), @splat(scalar)) };
    }

    /// Dot product (SIMD)
    pub inline fn dot(self: Self, other: Self) f64 {
        const prod = self.v * other.v;
        return prod[0] + prod[1] + prod[2];
    }

    /// Cross product (SIMD **not used here**, as vector indexing isn't supported in @Vector)
    pub inline fn cross(self: Self, other: Self) Self {
        return .{ .v = @Vector(3, f64){
            self.y() * other.z() - self.z() * other.y(),
            self.z() * other.x() - self.x() * other.z(),
            self.x() * other.y() - self.y() * other.x(),
        } };
    }
    /// Normalize vector
    pub inline fn normalize(self: Self) Self {
        const len = self.length();
        if (len == 0) return self;
        return self.scalarMul(1.0 / len);
    }

    /// Reflect a vector around a normal
    pub inline fn reflect(v: Self, n: Self) Self {
        return v.sub(n.scalarMul(v.dot(n) * 2.0));
    }

    /// Refract a vector given a normal and refraction index
    pub inline fn refract(uv: Self, n: Self, etai_over_etat: f64) Self {
        const cos_theta = rtweekend.fmin(uv.dot(n), 1.0);
        const r_out_perp = uv.sub(n.scalarMul(cos_theta)).scalarMul(etai_over_etat);
        const r_out_parallel = n.scalarMul(-math.sqrt(rtweekend.fabs(1.0 - r_out_perp.lengthSquared())));
        return r_out_perp.add(r_out_parallel);
    }
    pub inline fn nearZero(self: Self) bool {
        const s = 1e-8;
        return math.approxEqAbs(f64, self.x(), 0, s) and
            math.approxEqAbs(f64, self.y(), 0, s) and
            math.approxEqAbs(f64, self.z(), 0, s);
    }

    /// Negative vector
    pub inline fn negative(self: Self) Self {
        return .{ .v = -self.v };
    }

    /// Generate a random vector inside a unit disk
    pub inline fn randomInUnitDisk() Self {
        while (true) {
            const p = vec3(rtweekend.randomDoubleMinMax(-1, 1), rtweekend.randomDoubleMinMax(-1, 1), 0);
            if (p.lengthSquared() < 1) return p;
        }
    }

    /// Generate a random unit vector
    pub inline fn randomUnitVector() Self {
        while (true) {
            const p = Self.random();
            const lensq = p.lengthSquared();
            if (1e-160 < lensq and lensq <= 1) {
                return p.scalarDivision(math.sqrt(lensq));
            }
        }
    }

    /// Generate a random vector on the hemisphere around a normal
    pub inline fn randomOnHemisphere(normal: Self) Self {
        const on_unit_sphere = Self.randomUnitVector();
        if (normal.dot(on_unit_sphere) > 0.0) {
            return on_unit_sphere;
        }
        return on_unit_sphere.negative();
    }

    /// Generate a random vector in a unit cube
    pub inline fn random() Self {
        return vec3(rtweekend.randomDouble(), rtweekend.randomDouble(), rtweekend.randomDouble());
    }

    /// Generate a random vector with components in a range
    pub inline fn randomMinMax(min: comptime_float, max: comptime_float) Self {
        return vec3(rtweekend.randomDoubleMinMax(min, max), rtweekend.randomDoubleMinMax(min, max), rtweekend.randomDoubleMinMax(min, max));
    }
};

pub const vec3 = Vec3.init;

// Example Usage
pub fn main() void {
    var a = vec3(1.0, 2.0, 3.0);
    const b = vec3(4.0, 5.0, 6.0);

    var c = a.add(b);
    std.debug.print("x: {}, y: {}, z: {}\n", .{ c.x(), c.y(), c.z() });
}
