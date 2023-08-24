# Zig Bloom Filter

Wrote a simple Bloom filter to learn some Zig.

A [Bloom filter](https://en.wikipedia.org/wiki/Bloom_filter) is a space-efficient, probabilistic data structure that is used to test whether an element is a member of a set. False positive matches are possible, but false negatives are not.

Parameters:  
* $m$, space (number of bits)  
* $n$, number of elements  
* $k$, number of hash functions  
* $f$, false positive rate  

False positive rate as a function of $m$, $n$, $k$:  
$f \approx (1-e^{-\frac{nk}{m}})^k$

Number of bits given $n$, $f$:  
$m = \frac{-nln(f)}{ln(2)^2}$

Number of hash functions given $m$, $n$:  
$k = \frac{mln(2)}{n}$

## Implementation
Memory size of Bloom filter is specified and allocated at runtime initialization and uses Murmur3 hash functions.

```zig
const std = @import("std");
const expect = std.testing.expect;
const BloomFilter = @import("bloom_filter.zig").BloomFilter;

pub fn main() !void {
    var filter = try BloomFilter.init(std.heap.page_allocator, 100_000, 0.01);
    defer filter.deinit();

    try filter.insert("hi");
    try expect(try filter.contains("hi") == true);
    try expect(try filter.contains("yo") == false);
```