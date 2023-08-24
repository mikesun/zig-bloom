const std = @import("std");
const expect = std.testing.expect;
const BloomFilter = @import("bloom_filter.zig").BloomFilter;

pub fn main() !void {
    var filter = try BloomFilter.init(std.heap.page_allocator, 100_000, 0.01);
    defer filter.deinit();

    try filter.insert("hi");
    try expect(try filter.contains("hi") == true);
    try expect(try filter.contains("yo") == false);
}
