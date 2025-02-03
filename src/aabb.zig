const interval = @import("interval.zig").interval;
const intervalByBox = @import("interval.zig").intervalByBox;
const Interval = @import("interval.zig").Interval;
const Vec3 = @import("vec.zig").Vec3;
const Ray = @import("ray.zig").Ray;

pub const aabb = struct {
    x: Interval,
    y: Interval,
    z: Interval,

    const Self = @This();

    pub fn init(x: Interval, y: Interval, z: Interval) Self {
        return Self{ .x = x, .y = y, .z = z };
    }

    pub fn initByBounds(a: Vec3, b: Vec3) Self {
        return Self{
            .x = if (a.x() <= b.x()) interval(a.x(), b.x()) else interval(b.x(), a.x()),
            .y = if (a.y() <= b.y()) interval(a.y(), b.y()) else interval(b.y(), a.y()),
            .z = if (a.z() <= b.z()) interval(a.z(), b.z()) else interval(b.z(), a.z()),
        };
    }
    pub fn initByBoxes(box0: aabb, box1: aabb) Self {
        return Self{
            .x = intervalByBox(box0.x, box1.x),
            .y = intervalByBox(box0.y, box1.y),
            .z = intervalByBox(box0.z, box1.z),
        };
    }
    pub fn axis_interval(self: Self, n: u8) Interval {
        if (n == 1) return self.y;
        if (n == 2) return self.z;
        return self.x;
    }
    pub fn hit(self: Self, r: Ray, ray_t: Interval) bool {
        var temp_t = ray_t;
        const ray_orig = r.origin;
        const ray_dir = r.direction;
        for (0..3) |axis| {
            const ax = self.axis_interval(@as(u8, @intCast(axis)));
            const adinv = 1.0 / ray_dir.v[axis];

            const t0 = (ax.min - ray_orig.v[axis]) * adinv;
            const t1 = (ax.max - ray_orig.v[axis]) * adinv;

            if (t0 < t1) {
                if (t0 > temp_t.min) temp_t.min = t0;
                if (t1 < temp_t.max) temp_t.max = t1;
            } else {
                if (t1 > temp_t.min) temp_t.min = t1;
                if (t0 < temp_t.max) temp_t.max = t0;
            }

            if (temp_t.max <= temp_t.min)
                return false;
        }
        return true;
    }
    pub fn longestAxis(self: Self) i64 {
        if (self.x.size() > self.y.size()) {
            return if (self.x.size() > self.z.size()) 0 else 2;
        }
        return if (self.y.size() > self.z.size()) 1 else 2;
    }
};

pub const AABB = aabb.init;
pub const AABBBounded = aabb.initByBounds;
pub const AABBBoxes = aabb.initByBoxes;
