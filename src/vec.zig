const std = @import("std");
const rtweekend = @import("rtweekend.zig");
const math = std.math;

pub const Vec3 = struct {
    x: f64,
    y: f64,
    z: f64,
    const Self = @This();
    /// Constructor to initialize a Vec3
    pub fn init(x: f64, y: f64, z: f64) Self {
        return .{ .x = x, .y = y, .z = z };
    }
    /// vector euclidean magnitude
    pub fn lengthSquared(self: Self) f64 {
        return self.x * self.x + self.y * self.y + self.z * self.z;
    }

    pub fn length(self: Self) f64 {
        return math.sqrt(self.lengthSquared());
    }

    // unit length
    pub fn normalize(self: Self) Self {
        const len = self.length();
        if (len == 0) return self; // Avoid division by zero
        return .{
            .x = self.x / len,
            .y = self.y / len,
            .z = self.z / len,
        };
    }

    /// Vec3 addition
    pub fn add(self: Self, other: Self) Self {
        return .{
            .x = self.x + other.x,
            .y = self.y + other.y,
            .z = self.z + other.z,
        };
    }

    /// Vec3 substraction
    pub fn sub(self: Self, other: Self) Self {
        return .{
            .x = self.x - other.x,
            .y = self.y - other.y,
            .z = self.z - other.z,
        };
    }

    /// Multiply vector by a scalar
    pub fn scalarMul(self: Self, scalar: f64) Self {
        return .{
            .x = self.x * scalar,
            .y = self.y * scalar,
            .z = self.z * scalar,
        };
    }

    /// Divide vector by a scalar
    pub fn scalarDivision(self: Self, scalar: f64) Self {
        return .{
            .x = self.x * (1 / scalar),
            .y = self.y * (1 / scalar),
            .z = self.z * (1 / scalar),
        };
    }
    /// Dot product with another Vec3
    pub fn dot(self: Self, other: Self) f64 {
        return self.x * other.x + self.y * other.y + self.z * other.z;
    }
    pub fn unitVector(self: Self) Self {
        const len = self.length();
        if (len == 0) {
            @panic("Cannot normalize a zero vector");
        }
        return self.scalarDivision(len);
    }

    pub fn randomUnitVector() Self {
        while (true) {
            const p = Self.random();
            const lensq = p.lengthSquared();

            if (1e-160 < lensq and lensq <= 1) {
                return p.scalarDivision(math.sqrt(lensq));
            }
        }
    }

    pub fn randomOnHemisphere(normal: Self) Self {
        const on_unit_sphere = Self.randomUnitVector();

        if (normal.dot(on_unit_sphere) > 0.0) {
            return on_unit_sphere;
        }
        return on_unit_sphere.negative();
    }
    /// Cross product with another Vec3
    pub fn cross(self: Self, other: Self) Self {
        return .{
            .x = self.y * other.z - self.z * other.y,
            .y = self.z * other.x - self.x * other.z,
            .z = self.x * other.y - self.y * other.x,
        };
    }
    pub fn negative(self: Self) Self {
        return vec3(-self.x, -self.y, -self.z);
    }

    pub fn random() Self {
        return .{
            .x = rtweekend.randomDouble(),
            .y = rtweekend.randomDouble(),
            .z = rtweekend.randomDouble(),
        };
    }
    pub fn randomMinMax(min: f64, max: f64) Self {
        return .{
            .x = rtweekend.randomDoubleMinMax(min, max),
            .y = rtweekend.randomDoubleMinMax(min, max),
            .z = rtweekend.randomDoubleMinMax(min, max),
        };
    }
};

pub const vec3 = Vec3.init;
