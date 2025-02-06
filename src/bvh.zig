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
const Thread = std.Thread;

const InitArgs = struct {
    allocator: *Allocator,
    objects: std.ArrayList(HitTable),
    start: usize,
    end: usize,
    results: *std.ArrayList(*BVHNode),
    mutex: *Thread.Mutex,
};

pub const BVHNode = struct {
    left: *HitTable,
    right: *HitTable,
    bbox: aabb,

    const Self = @This();
    pub fn initFromList(allocator: *Allocator, list: *HitTableList) !Self {
        return try Self.init(allocator, list.objects, 0, list.objects.items.len);
    }

    fn initLeftNode(args: *InitArgs) !void {
        const left_node = try args.allocator.create(BVHNode);
        left_node.* = try Self.init(args.allocator, args.objects, args.start, args.end);

        args.mutex.lock();
        defer args.mutex.unlock();
        try args.results.*.append(left_node);
    }

    fn initRightNode(args: *InitArgs) !void {
        const right_node = try args.allocator.create(BVHNode);
        right_node.* = try Self.init(args.allocator, args.objects, args.start, args.end);

        args.mutex.lock();
        defer args.mutex.unlock();

        try args.results.*.append(right_node);
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

        var results: std.ArrayList(*BVHNode) = std.ArrayList(*BVHNode).init(allocator.*);
        try results.ensureTotalCapacity(2);
        var mutex = Thread.Mutex{};

        var left_args = InitArgs{
            .allocator = allocator,
            .objects = objects,
            .start = start,
            .end = mid,
            .results = &results,
            .mutex = &mutex,
        };
        var right_args = InitArgs{
            .allocator = allocator,
            .objects = objects,
            .start = mid,
            .end = end,
            .results = &results,
            .mutex = &mutex,
        };
        const threadConfig = Thread.SpawnConfig{
            .stack_size = 1024 * 16,
        };
        const thread1 = try Thread.spawn(threadConfig, initLeftNode, .{&left_args});
        const thread2 = try Thread.spawn(threadConfig, initRightNode, .{&right_args});

        thread1.join();
        thread2.join();

        const left_node_ptr = results.items[0];
        const right_node_ptr = results.items[1];

        const left: *HitTable = try allocator.create(HitTable);
        left.* = HitTable{ .bvhNode = left_node_ptr.* };

        const right: *HitTable = try allocator.create(HitTable);
        right.* = HitTable{ .bvhNode = right_node_ptr.* };

        return Self{
            .left = left,
            .right = right,
            .bbox = bbox,
        };
    }

    pub inline fn boxCompare(a: HitTable, b: HitTable, axisIndex: u8) bool {
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
