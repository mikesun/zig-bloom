const std = @import("std");
const expect = std.testing.expect;
const math = std.math;
const Allocator = std.mem.Allocator;
const BitArray = @import("bit_array.zig").BitArray;
const Murmur = std.hash.Murmur3_32;

/// Bloom filter with allocation of bit array at runtime initialization. Uses
/// Murmur3 hash functions.
pub const BloomFilter = struct {
    num_hash_funcs: usize,
    bits: BitArray,

    /// Initialize a new Bloom filter
    pub fn init(
        allocator: std.mem.Allocator,
        num_items: usize,
        fp_rate: f32,
    ) Allocator.Error!BloomFilter {
        const m = calcM(num_items, fp_rate);
        const k = calcK(num_items, m);

        return BloomFilter{
            .num_hash_funcs = k,
            .bits = try BitArray.init(allocator, m),
        };
    }

    /// Deinitialize and free resources
    pub fn deinit(self: *BloomFilter) void {
        self.bits.deinit();
    }

    /// Insert an item into the Bloom filter.
    pub fn insert(self: *BloomFilter, item: []const u8) !void {
        for (0..self.num_hash_funcs) |i| {
            try self.bits.setBit(self.calcBitIdx(item, i));
        }
    }

    /// Returns whether Bloom filter contains the item. It may return a false
    /// positive, but will never return a false negative.
    pub fn contains(self: *BloomFilter, item: []const u8) !bool {
        for (0..self.num_hash_funcs) |i| {
            if (try self.bits.getBit(self.calcBitIdx(item, i)) == 0) {
                return false;
            }
        }
        return true;
    }

    /// Calculate index of bit for given item and hashing function seed
    fn calcBitIdx(self: *BloomFilter, item: []const u8, hash_seed: usize) usize {
        const hash = Murmur.hashWithSeed(item, @truncate(hash_seed));
        return hash % self.bits.len;
    }
};

/// Calculate the appropriate size in bits of the Bloom filter, `m`, given
/// `n` and `f`, the expected number of elements contained in the Bloom filter and the
/// target false positive rate, respectively.
///
/// `(-nln(f))/ln(2)^2`
fn calcM(n: usize, f: f32) usize {
    var numerator = @as(f32, @floatFromInt(n)) * -math.log(f32, math.e, f);
    var denominator = math.pow(f32, (math.log(f32, math.e, 2)), 2);
    return @as(usize, @intFromFloat(
        math.divTrunc(f32, numerator, denominator) catch unreachable,
    ));
}

/// Calculate the number of hash functions to use, `k`, given `n` and `m`, the expected
/// number of elements contained in the Bloom filter and the size in bits of the Bloom
/// filter.
///
/// `(mln(2)/n)`
fn calcK(n: usize, m: usize) usize {
    // https://en.wikipedia.org/wiki/Bloom_filter#Optimal_number_of_hash_functions
    var numerator = @as(f32, @floatFromInt(m)) * math.log(f32, math.e, 2);
    var denominator = @as(f32, @floatFromInt(n));
    return @as(usize, @intFromFloat(
        math.divTrunc(f32, numerator, denominator) catch unreachable,
    ));
}

test "calcM" {
    const n: usize = 1_000_000;
    const f: f32 = 0.02;
    try expect(calcM(n, f) == 8_142_363);
}

test "calcK" {
    const n: usize = 1_000_000;
    const m: usize = 8_142_363;
    try expect(calcK(n, m) == 5);
}

test "init" {
    var filter = try BloomFilter.init(std.testing.allocator, 100_000, 0.02);
    defer filter.deinit();
}

test "contains_true" {
    var filter = try BloomFilter.init(std.testing.allocator, 100_000, 0.02);
    defer filter.deinit();

    try filter.insert("hi");
    try expect(try filter.contains("hi") == true);
}

test "contains_false" {
    var filter = try BloomFilter.init(std.testing.allocator, 100_000, 0.02);
    defer filter.deinit();

    try filter.insert("hi");
    try expect(try filter.contains("yo") == false);
}
