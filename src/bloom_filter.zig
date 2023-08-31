const std = @import("std");
const expect = std.testing.expect;
const math = std.math;
const Allocator = std.mem.Allocator;
const BitArray = @import("bit_array.zig").BitArray;
const Murmur = std.hash.Murmur3_32;

const BloomFilterError = error{
    UnsupportedSpec,
};

/// Bloom filter with allocation of bit array at runtime initialization. Uses
/// Murmur3 hash functions.
pub const BloomFilter = struct {
    num_hash_funcs: u8,
    bits: BitArray,

    /// Initialize a new Bloom filter that is configured and sized to hold
    /// a specified maximum number of items with a given false positive rate.
    pub fn init(
        allocator: std.mem.Allocator,
        max_items: u64,
        fp_rate: f32,
    ) !BloomFilter {
        const m = calcM(max_items, fp_rate);
        const k = calcK(max_items, m);

        // check `k` is <= 256
        if (k > std.math.maxInt(u8)) {
            return BloomFilterError.UnsupportedSpec;
        }

        return BloomFilter{
            .num_hash_funcs = @truncate(k),
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
            try self.bits.setBit(self.calcBitIdx(item, @truncate(i)));
        }
    }

    /// Returns whether Bloom filter contains the item. It may return a false
    /// positive, but will never return a false negative.
    pub fn contains(self: *BloomFilter, item: []const u8) !bool {
        for (0..self.num_hash_funcs) |i| {
            if (try self.bits.getBit(self.calcBitIdx(item, @truncate(i))) == 0) {
                return false;
            }
        }
        return true;
    }

    /// Calculate index of bit for given item and hashing function seed
    fn calcBitIdx(self: *BloomFilter, item: []const u8, hash_seed: u32) u64 {
        const hash = Murmur.hashWithSeed(item, hash_seed);
        return hash % self.bits.len;
    }
};

/// Calculate the appropriate number in bits of the Bloom filter, `m`, given
/// `n`, the expected number of elements contained in the Bloom filter and the
/// target false positive rate, `f`.
///
/// `(-nln(f))/ln(2)^2`
fn calcM(n: u64, f: f64) u64 {
    var numerator = @as(f64, @floatFromInt(n)) * -math.log(f64, math.e, f);
    var denominator = math.pow(f64, (math.log(f64, math.e, 2)), 2);
    return @intFromFloat(
        math.divTrunc(f64, numerator, denominator) catch unreachable,
    );
}

/// Calculate the number of hash functions to use, `k`, given `n` and `m`, the expected
/// number of elements contained in the Bloom filter and the size in bits of the Bloom
/// filter.
///
/// `(mln(2)/n)`
fn calcK(n: u64, m: u64) u64 {
    // https://en.wikipedia.org/wiki/Bloom_filter#Optimal_number_of_hash_functions
    var numerator = @as(f64, @floatFromInt(m)) * math.log(f64, math.e, 2);
    var denominator = @as(f64, @floatFromInt(n));
    return @as(u64, @intFromFloat(
        math.divTrunc(f64, numerator, denominator) catch unreachable,
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
