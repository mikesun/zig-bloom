const std = @import("std");
const expect = std.testing.expect;
const BloomFilter = @import("bloom_filter.zig").BloomFilter;

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    const num_items: u64 = 100;
    try stdout.print("num_items={}\n", .{num_items});

    var filter = try BloomFilter.init(std.heap.page_allocator, num_items, 0.01);
    defer filter.deinit();
    try stdout.print("bit_array size in bytes = {}\n", .{filter.bits.bytes.len});

    var buf = [_]u8{undefined} ** 100;
    const t = try std.fmt.bufPrint(&buf, "item_{d}", .{111111111111});
    std.debug.print("t: {s}\n", .{t});
    for (0..num_items) |i| {
        const item = try std.fmt.bufPrint(&buf, "item_{d}", .{i});
        std.debug.print("item: {s}\n", .{item});
        try filter.insert(item);
    }
}
