const std = @import("std");
const expect = std.testing.expect;
const BloomFilter = @import("bloom_filter.zig").BloomFilter;

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    // Number of items to add to Bloom filter
    const num_items: u64 = 100_000_000;
    try stdout.print("num_items={}\n", .{num_items});

    // Initialize Bloom filter
    var filter = try BloomFilter.init(std.heap.page_allocator, num_items, 0.01);
    defer filter.deinit();
    std.debug.print("bit_array size in bytes = {}\n", .{filter.bits.bytes.len});

    // Insert items into Bloom filter
    for (0..num_items) |i| {
        var buf: [100]u8 = undefined;
        const item = try std.fmt.bufPrint(&buf, "item_{d}", .{i});
        try filter.insert(item);
    }

    // // Verify no false negatives
    // for (0..num_items) |i| {
    //     var buf: [100]u8 = undefined;
    //     const item = try std.fmt.bufPrint(&buf, "item_{d}", .{i});
    //     if (!try filter.contains(item)) std.debug.panic("false negative: {s}", .{item});
    // }
    // try stdout.print("no false negatives\n", .{});
}
