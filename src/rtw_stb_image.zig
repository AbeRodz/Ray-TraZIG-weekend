const std = @import("std");

const c = @cImport({
    @cInclude("stb_image.h");
});

pub const Image = struct {
    width: i32 = 0,
    height: i32 = 0,
    bytes_per_pixel: i32 = 3,
    bytes_per_scanline: i32 = 0,
    fdata: [*]f32 = undefined, // Floating point pixel data
    bdata: []u8 = undefined, // 8-bit pixel data

    pub fn init(filename: []const u8, allocator: std.mem.Allocator) !Image {
        var image: Image = .{};
        var components: i32 = 0;
        const ptr: [*c]f32 = c.stbi_loadf(
            filename.ptr,
            &image.width,
            &image.height,
            &components,
            image.bytes_per_pixel,
        );
        if (ptr == null) return error.FailedToLoadImage;
        // if (image.fdata == null) {
        //     return error.ImageLoadFailed;
        // }
        image.fdata = ptr;
        image.bytes_per_scanline = image.width * image.bytes_per_pixel;
        try image.convert_to_bytes(allocator);

        return image;
    }

    pub fn deinit(self: *Image, allocator: std.mem.Allocator) void {
        if (self.fdata != null) c.stbi_image_free(self.fdata);
        if (self.bdata != null) allocator.free(self.bdata);
    }

    pub fn pixel_data(self: *const Image, x: i32, y: i32) [*]const u8 {
        // Returns pointer to RGB pixel data at (x, y). Returns magenta for out-of-bounds access.
        const magenta: [3]u8 = .{ 255, 0, 255 };
        if (self.bdata.len == 0) return &magenta;

        const clamped_x = @as(i32, @intCast(@max(0, @min(x, self.width - 1))));
        const clamped_y = @as(i32, @intCast(@max(0, @min(y, self.height - 1))));
        const index = @as(usize, @intCast(clamped_y * self.bytes_per_scanline + clamped_x * self.bytes_per_pixel));
        const pixel_size = @as(usize, @intCast(self.bytes_per_pixel));

        // Ensure safe bounds before accessing memory
        if (index + pixel_size > self.bdata.len) return &magenta;

        return self.bdata.ptr + index; // Return a pointer instead of a slice
    }

    fn convert_to_bytes(self: *Image, allocator: std.mem.Allocator) !void {
        // Converts floating-point pixel data to 8-bit RGB values.

        const total_bytes = @as(usize, @intCast(self.width * self.height * self.bytes_per_pixel));
        self.bdata = try allocator.alloc(u8, total_bytes);

        var bptr = self.bdata;
        const fptr = self.fdata;

        for (0..total_bytes) |i| {
            bptr[i] = self.float_to_byte(fptr[i]);
        }
    }

    fn float_to_byte(_: *const Image, value: f32) u8 {
        return if (value <= 0.0) 0 else if (value >= 1.0) 255 else @intFromFloat(value * 256.0);
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var image = try Image.init("raccoon.jpg", allocator);
    defer image.deinit(allocator);

    std.debug.print("Image loaded: {}x{}\n", .{ image.width, image.height });

    const pixel = image.pixel_data(10, 10);
    std.debug.print("Pixel at (10,10): R={} G={} B={}\n", .{ pixel[0], pixel[1], pixel[2] });
}
