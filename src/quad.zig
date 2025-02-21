const HitRecord = @import("hittable.zig").HitRecord;
const Material = @import("material.zig").Material;
const Vec3 = @import("vec.zig").Vec3;
const Ray = @import("ray.zig").Ray;
const Interval = @import("interval.zig").Interval;
const aabb = @import("aabb.zig").aabb;

pub const Quad = struct {
    Q: Vec3,
    u: Vec3,
    v: Vec3,
    w: Vec3,
    material: *const Material,
    bbox: aabb,
    normal: Vec3,
    D: f64,

    const Self = @This();

    pub fn init(Q: Vec3, u: Vec3, v: Vec3, material: *const Material) Self {
        var quad = Self{
            .Q = Q,
            .u = u,
            .v = v,
            .material = material,
            .w = undefined,
            .bbox = undefined,
            .normal = undefined,
            .D = undefined,
        };
        const n = Vec3.cross(u, v);
        quad.normal = Vec3.unitVector(n);
        quad.D = Vec3.dot(quad.normal, Q);
        quad.w = n.scalarDivision(Vec3.dot(n, n));
        quad.SetBoundingBox();
        return quad;
    }

    fn SetBoundingBox(self: *Self) void {
        const bbox_diagonal1 = aabb.initByBounds(self.Q, self.Q.add(self.u).add(self.v));
        const bbox_diagonal2 = aabb.initByBounds(self.Q.add(self.u), self.Q.add(self.v));
        self.bbox = aabb.initByBoxes(bbox_diagonal1, bbox_diagonal2);
    }
    pub fn hit(self: Self, r: Ray, interval: Interval, rec: *HitRecord) bool {
        const denom = self.normal.dot(r.direction);

        // No hit if the ray is parallel to the plane.
        if (@abs(denom) < 1e-8)
            return false;

        // Return false if the hit point parameter t is outside the ray interval.
        const t = (self.D - self.normal.dot(r.origin)) / denom;
        if (!interval.contains(t))
            return false;

        const intersection = r.at(t);
        const planar_hitpt_vector = intersection.sub(self.Q);
        const alpha = self.w.dot(planar_hitpt_vector.cross(self.v));
        const beta = self.w.dot(self.u.cross(planar_hitpt_vector));

        if (!is_interior(alpha, beta, rec))
            return false;
        rec.t = t;
        rec.point = intersection;
        rec.material = self.material;
        rec.setFaceNormal(r, self.normal);

        return true;
    }
    fn is_interior(a: f64, b: f64, hit_record: *HitRecord) bool {
        const unit_interval = Interval.init(0, 1);
        if (!unit_interval.contains(a) or !unit_interval.contains(b))
            return false;

        hit_record.u = a;
        hit_record.v = b;
        return true;
    }
    pub inline fn bounding_box(self: Self) aabb {
        return self.bbox;
    }
};
