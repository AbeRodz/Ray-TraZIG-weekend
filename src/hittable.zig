const std = @import("std");
const ray = @import("ray.zig");
const Ray = @import("ray.zig").Ray;
const Vec3 = @import("vec.zig").Vec3;
const Sphere = @import("sphere.zig").Sphere;
const Quad = @import("quad.zig").Quad;
const Interval = @import("interval.zig").Interval;
const Material = @import("material.zig").Material;
const aabb = @import("aabb.zig").aabb;
const BVHNode = @import("bvh.zig").BVHNode;

pub const HitTable = union(enum) {
    sphere: Sphere,
    bvhNode: BVHNode,
    quad: Quad,
    const Self = @This();
    pub fn hit(self: Self, r: Ray, interval: Interval, rec: *HitRecord) bool {
        switch (self) {
            inline else => |h| return h.hit(r, interval, rec),
        }
    }

    pub fn bounding_box(self: Self) aabb {
        switch (self) {
            inline else => |h| return h.bounding_box(),
        }
    }
};
pub const HitRecord = struct {
    point: Vec3,
    normal: Vec3,
    material: *const Material,
    t: f64,
    u: f64,
    v: f64,
    front_face: bool,

    const Self = @This();

    pub fn setFaceNormal(self: *Self, r: Ray, outward_normal: Vec3) void {
        self.front_face = r.direction.dot(outward_normal) < 0;
        self.normal = if (self.front_face) outward_normal else outward_normal.negative();
    }
};

pub const HitRecordPool = struct {
    records: []HitRecord,
    free_list: []?*HitRecord, // Stack of available records
    top: usize, // Points to the next available slot

    pub fn init(allocator: *std.mem.Allocator, max_size: usize) !HitRecordPool {
        var records = try allocator.alloc(HitRecord, max_size);
        var free_list = try allocator.alloc(?*HitRecord, max_size);

        // Initialize free list with all records
        for (0..max_size) |i| {
            free_list[i] = &records[i];
        }

        return HitRecordPool{
            .records = records,
            .free_list = free_list,
            .top = max_size, // All records are initially free
        };
    }

    pub fn deinit(self: *HitRecordPool, allocator: *std.mem.Allocator) void {
        allocator.free(self.records);
        allocator.free(self.free_list);
    }

    pub fn get(self: *HitRecordPool) ?*HitRecord {
        if (self.top == 0) return null; // No more available records
        self.top -= 1;
        return self.free_list[self.top];
    }

    pub fn release(self: *HitRecordPool, record: *HitRecord) void {
        if (self.top >= self.free_list.len) return; // Prevent overflow
        self.free_list[self.top] = record;
        self.top += 1;
    }

    pub fn available(self: *HitRecordPool) usize {
        return self.top; // Number of free records
    }
};
