const std = @import("std");
const Ray = @import("ray.zig").Ray;
const aabb = @import("aabb.zig").aabb;
const AABBBoxes = @import("aabb.zig").AABBBoxes;
const HitTable = @import("hittable.zig").HitTable;
const HitRecord = @import("hittable.zig").HitRecord;
const ArrayList = @import("std").ArrayList;
const Interval = @import("interval.zig").Interval;
const interval = @import("interval.zig").interval;

pub const HitTableList = struct {
    objects: ArrayList(HitTable),
    bbox: aabb,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .objects = ArrayList(HitTable).init(allocator),
            .bbox = undefined,
        };
    }
    pub fn deinit(self: *Self) void {
        self.objects.deinit();
    }
    pub fn add(self: *Self, object: HitTable) !void {
        try self.objects.append(object);
        self.bbox = AABBBoxes(self.bbox, object.bounding_box());
    }
    pub fn bounding_box(self: Self) aabb {
        return self.bbox;
    }

    pub fn hit(self: Self, r: Ray, hit_interval: Interval, hit_record: *HitRecord) bool {
        var temp_hit_record: HitRecord = undefined;
        const temp_rec = &temp_hit_record;
        var hit_anything = false;
        var closest_so_far = hit_interval.max;

        for (self.objects.items) |object| {
            if (object.hit(r, interval(hit_interval.min, closest_so_far), temp_rec)) {
                hit_anything = true;
                closest_so_far = temp_rec.t;
                hit_record.* = temp_rec.*;
            }
        }
        return hit_anything;
    }
};
