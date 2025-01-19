const std = @import("std");
const ppm = @import("ppm.zig");

pub fn main() !void {
    const width = 256;
    const height = 256;

    var buffered_writer = std.io.bufferedWriter(std.io.getStdOut().writer());
    const writer = buffered_writer.writer();

    try ppm.ppmWriter(&writer, width, height);
    try buffered_writer.flush();
    std.debug.print("PPM file generated successfully.\n", .{});
}
