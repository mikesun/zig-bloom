const std = @import("std");
const expect = std.testing.expect;
const Allocator = std.mem.Allocator;

const BitArrayError = error{InvalidBitOffset};

pub const BitArray = struct {
    allocator: Allocator,

    /// Slice of bytes used as bit store.
    bytes: []u8,

    /// Length in bits of the bit array.
    len: usize,

    /// Initialize new BitArray given allocator and length in bits of BitArray.
    pub fn init(allocator: Allocator, num_bits: usize) Allocator.Error!BitArray {
        const num_bytes = if (num_bits % 8 > 0) (num_bits / 8) + 1 else (num_bits / 8);
        var bytes = try allocator.alloc(u8, num_bytes);
        @memset(bytes, 0);

        return BitArray{
            .allocator = allocator,
            .bytes = bytes,
            .len = num_bits,
        };
    }

    /// Deinitialize and free resources
    pub fn deinit(self: *BitArray) void {
        self.allocator.free(self.bytes);
    }

    /// Get value of bit.
    pub fn getBit(self: *BitArray, idx: usize) BitArrayError!u1 {
        try self.isValidBitIdx(idx);
        const offset = bitOffset(idx);
        return @truncate(
            ((self.bytes[byteIdx(idx)] & (@as(u8, 1) << offset))) >> offset,
        );
    }

    /// Set value of bit to 1.
    pub fn setBit(self: *BitArray, idx: usize) BitArrayError!void {
        try self.isValidBitIdx(idx);
        self.bytes[byteIdx(idx)] |= @as(u8, 1) << bitOffset(idx);
    }

    /// Clear value of bit to 0.
    pub fn clearBit(self: *BitArray, idx: usize) BitArrayError!void {
        try self.isValidBitIdx(idx);
        self.bytes[byteIdx(idx)] &= ~(@as(u8, 1) << bitOffset(idx));
    }

    /// Toggle value of bit.
    pub fn toggleBit(self: *BitArray, idx: usize) BitArrayError!void {
        try self.isValidBitIdx(idx);
        self.bytes[byteIdx(idx)] ^= @as(u8, 1) << bitOffset(idx);
    }

    fn isValidBitIdx(self: *BitArray, idx: usize) BitArrayError!void {
        if (idx >= self.len) return BitArrayError.InvalidBitOffset;
    }
};

fn byteIdx(bit_idx: usize) usize {
    return bit_idx / 8;
}

fn bitOffset(bit_idx: usize) u3 {
    return @truncate(bit_idx % 8);
}

test "init_deinit" {
    var bits = try BitArray.init(std.testing.allocator, 1000);
    defer bits.deinit();
}

test "get" {
    var bits = try BitArray.init(std.testing.allocator, 1000);
    defer bits.deinit();

    try expect(0 == try bits.getBit(200));
}

test "set" {
    var bits = try BitArray.init(std.testing.allocator, 1000);
    defer bits.deinit();

    try bits.setBit(200);
    try expect(1 == try bits.getBit(200));
}

test "clear" {
    var bits = try BitArray.init(std.testing.allocator, 1000);
    defer bits.deinit();

    try bits.setBit(400);
    try bits.clearBit(400);
    try expect(0 == try bits.getBit(400));
}

test "toggle" {
    var bits = try BitArray.init(std.testing.allocator, 1000);
    defer bits.deinit();

    try bits.toggleBit(400);
    try expect(1 == try bits.getBit(400));
}
