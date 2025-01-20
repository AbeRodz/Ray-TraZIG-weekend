const std = @import("std");
const math = std.math;

pub const rand_gen = std.rand.DefaultPrng;

pub const Vec3 = struct {
    x: f64,
    y: f64,
    z: f64,

    /// Constructor to initialize a Vec3
    pub fn init(x: f64, y: f64, z: f64) Vec3 {
        return Vec3{ .x = x, .y = y, .z = z };
    }
    /// vector euclidean magnitude
    pub fn length(self: Vec3) f64 {
        return math.sqrt(self.x * self.x + self.y * self.y + self.z * self.z);
    }

    // unit length
    pub fn normalize(self: Vec3) Vec3 {
        const len = self.length();
        if (len == 0) return self; // Avoid division by zero
        return Vec3{
            .x = self.x / len,
            .y = self.y / len,
            .z = self.z / len,
        };
    }

    /// Vec3 addition
    pub fn add(self: Vec3, other: Vec3) Vec3 {
        return Vec3{
            .x = self.x + other.x,
            .y = self.y + other.y,
            .z = self.z + other.z,
        };
    }

    /// Vec3 substraction
    pub fn sub(self: Vec3, other: Vec3) Vec3 {
        return Vec3{
            .x = self.x - other.x,
            .y = self.y - other.y,
            .z = self.z - other.z,
        };
    }

    /// Multiply vector by a scalar
    pub fn scalarMul(self: Vec3, scalar: f64) Vec3 {
        return Vec3{
            .x = self.x * scalar,
            .y = self.y * scalar,
            .z = self.z * scalar,
        };
    }

    /// Dot product with another Vec3
    pub fn dot(self: Vec3, other: Vec3) f64 {
        return self.x * other.x + self.y * other.y + self.z * other.z;
    }

    /// Cross product with another Vec3
    pub fn cross(self: Vec3, other: Vec3) Vec3 {
        return Vec3{
            .x = self.y * other.z - self.z * other.y,
            .y = self.z * other.x - self.x * other.z,
            .z = self.x * other.y - self.y * other.x,
        };
    }
};
