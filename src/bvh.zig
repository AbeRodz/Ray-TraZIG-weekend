const std = @import("std");
const aabb = @import("aabb.zig").aabb;
const AABBBoxes = @import("aabb.zig").AABBBoxes;
const HitTable = @import("hittable.zig").HitTable;
const HitRecord = @import("hittable.zig").HitRecord;
const HitTableList = @import("hittable_list.zig").HitTableList;
const Ray = @import("ray.zig").Ray;
const Interval = @import("interval.zig").Interval;
const ArrayList = @import("std").ArrayList;
const rtweekend = @import("rtweekend.zig");
const Allocator = std.mem.Allocator;

pub const BVHNode = struct {
    left: *HitTable,
    right: *HitTable,
    bbox: aabb,

    const Self = @This();
    pub fn initFromList(allocator: *Allocator, list: *HitTableList) !Self {
        return try Self.init(allocator, list.objects, 0, list.objects.items.len);
    }

    pub fn init(allocator: *Allocator, objects: std.ArrayList(HitTable), start: usize, end: usize) !Self {
        const object_span = end - start;

        var bbox: aabb = undefined;

        // Compute bounding box
        for (start..end) |object_index| {
            bbox = AABBBoxes(bbox, objects.items[object_index].bounding_box());
        }

        if (object_span == 1) {
            const single_object = try allocator.create(HitTable);
            single_object.* = objects.items[start];

            return Self{
                .left = single_object,
                .right = single_object,
                .bbox = bbox,
            };
        } else if (object_span == 2) {
            const left = try allocator.create(HitTable);
            left.* = objects.items[start];

            const right = try allocator.create(HitTable);
            right.* = objects.items[start + 1];

            return Self{
                .left = left,
                .right = right,
                .bbox = bbox,
            };
        }

        // Sort objects by the longest axis
        const axis = bbox.longestAxis();
        switch (axis) {
            0 => std.mem.sortUnstable(HitTable, objects.items[start..end], {}, boxXCompare),
            1 => std.mem.sortUnstable(HitTable, objects.items[start..end], {}, boxYCompare),
            2 => std.mem.sortUnstable(HitTable, objects.items[start..end], {}, boxZCompare),
            else => unreachable,
        }

        const mid = start + object_span / 2;

        // Recursively construct BVH nodes
        const left_node = try allocator.create(BVHNode);
        left_node.* = try Self.init(allocator, objects, start, mid);

        const right_node = try allocator.create(BVHNode);
        right_node.* = try Self.init(allocator, objects, mid, end);

        // Wrap them in HitTable
        const left: *HitTable = try allocator.create(HitTable);
        left.* = HitTable{ .bvhNode = left_node.* };

        const right: *HitTable = try allocator.create(HitTable);
        right.* = HitTable{ .bvhNode = right_node.* };

        return Self{
            .left = left,
            .right = right,
            .bbox = bbox,
        };
    }

    // pub fn init(allocator: *Allocator, objects: ArrayList(HitTable), start: usize, end: usize) !Self {
    //     const object_span = end - start;
    //     // const leftNode = try allocator.create(BVHNode);
    //     // const rightNode = try allocator.create(BVHNode);

    //     var left = try allocator.create(HitTable);
    //     var right = try allocator.create(HitTable);
    //     var bbox: aabb = undefined;

    //     // Calculate bounding box
    //     for (start..end) |object_index| {
    //         bbox = AABBBoxes(bbox, objects.items[object_index].bounding_box());
    //     }

    //     const axis = bbox.longestAxis();

    //     if (object_span == 1) {
    //         left = &objects.items[start]; // Store the object in the node
    //         right = left; // In case it's the same object
    //     } else if (object_span == 2) {
    //         left = &objects.items[start]; // Store the object in the node
    //         right = &objects.items[start + 1]; // Store the object in the node
    //     } else {
    //         // Sort objects by selected axis
    //         switch (axis) {
    //             0 => std.mem.sortUnstable(HitTable, objects.items[start..end], {}, boxXCompare),
    //             1 => std.mem.sortUnstable(HitTable, objects.items[start..end], {}, boxYCompare),
    //             2 => std.mem.sortUnstable(HitTable, objects.items[start..end], {}, boxZCompare),
    //             else => unreachable,
    //         }

    //         const mid = start + object_span / 2;

    //         // Initialize left and right nodes
    //         var leftNode = try Self.init(allocator, objects, start, mid);
    //         var rightNode = try Self.init(allocator, objects, mid, end);
    //     }

    //     // Create the current node and assign left and right children
    //     var node = BVHNode{ .left = left }; // Initialize with the 'left' field

    //     // Reinitialize the union to set the 'right' field
    //     node = BVHNode{ .right = right };

    //     // Now you can assign the 'bbox' field, since 'right' is the active field
    //     node = BVHNode{ .bbox = bbox };

    //     // Assign the right and bounding box fields afterward
    //     //node.right = right;
    //     //node.bbox = bbox;
    //     // const node = try allocator.create(BVHNode);

    //     // node.*.bbox = bbox;

    //     // node.*.left = left;
    //     // node.*.right = right;

    //     return node;
    // }
    pub fn boxCompare(a: HitTable, b: HitTable, axisIndex: u8) bool {
        const a_axis_interval = a.bounding_box().axis_interval(axisIndex);
        const b_axis_interval = b.bounding_box().axis_interval(axisIndex);
        return a_axis_interval.min < b_axis_interval.min;
    }
    pub fn boxXCompare(_: void, a: HitTable, b: HitTable) bool {
        return boxCompare(a, b, 0);
    }
    pub fn boxYCompare(_: void, a: HitTable, b: HitTable) bool {
        return boxCompare(a, b, 1);
    }
    pub fn boxZCompare(_: void, a: HitTable, b: HitTable) bool {
        return boxCompare(a, b, 2);
    }

    pub fn hit(self: Self, r: Ray, ray_t: Interval, rec: *HitRecord) bool {
        if (!self.bbox.hit(r, ray_t))
            return false;

        const hit_left = self.left.hit(r, ray_t, rec);
        const hit_right = self.right.hit(r, Interval.init(ray_t.min, if (hit_left) rec.t else ray_t.max), rec);

        return hit_left or hit_right;
    }
    // Define comparator based on axis
    fn getComparator(axis: i64) *const fn (HitTable, HitTable) bool {
        return switch (axis) {
            0 => boxXCompare,
            1 => boxYCompare,
            2 => boxZCompare,
            else => unreachable,
        };
    }
    fn comparatorWrapper(_: void, a: HitTable, b: HitTable) bool {
        const axis: i64 = rtweekend.randomInt(0, 2);
        const comparator = getComparator(axis);
        return comparator(a, b); // Pass by pointer
    }
    pub fn bounding_box(self: Self) aabb {
        return self.bbox;
    }
};

pub const bvhNode = BVHNode.init;
