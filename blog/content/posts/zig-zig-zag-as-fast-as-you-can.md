---
title: "Zig Zig Zag, as Fast as You Can"
date: 2024-12-28T12:09:20-08:00
tags:
  - programming-challenges
  - programming-language-design
  - zig
---
In the spirit of one of my favourite books - [Seven Languages In Seven Weeks](https://pragprog.com/titles/btlang/seven-languages-in-seven-weeks/) - I've been working through this year's [Advent of Code](https://adventofcode.com/) in [Zig](https://ziglang.org/), a "_general-purpose programming language and toolchain for maintaining **robust, optimal**, and **reusable** software_"[^advent-of-code].
<!--more-->
More-specifically than that general description, Zig is a systems programming language - one which focuses on lower-level, resource-constrained, highly-optimized use-cases. This makes it a peer of the C-family, Rust[^rust], and GoLang. I'd love to do a future blog post comparing my experience with Zig, Rust, and GoLang[^comparison], but this is not that post. Rather, I wanted to do a little experiment to test my understanding - and I got some _very_ surprising results that I'm hoping someone can help me to work towards understanding.

I noticed that Zig's [HashMaps](https://zig.guide/standard-library/hashmaps/) have a `getAndPut` method, which was a bit puzzling to me, because the syntax suggests that it does _not_, in fact, `put` anything. That is[^running]:

```zig
const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    // You can ignore this - it's setting up an allocator, which is used for reserving and freeing memory
    // for Zig's objects. Systems Programming, ahoy! :P
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // "Create a Map<int, List<int>>"
    var map = std.AutoHashMap(u32, std.ArrayList(u32)).init(allocator);
    // This next line is a pattern of many Systems Programming languages - the necessity to
    // tell your system when to free up memory allocated to a variable.
    //
    // In support of Zig - not only does `defer` (which defers execution until the enclosing function returns)
    // make this easier to do, but the toolchain also identifies memory leaks for you.
    defer map.deinit();

    print("Is the key present _before_ getOrPut? {}\n", .{map.contains(1)});

    const response = try map.getOrPut(1);
    // At this point, there is still nothing "at" the value - that is, if the following line were uncommented,
    // it would cause an error
    // print("{}\n", .{response.value_ptr});
    //
    // But there is a key in the map:
    print("Is the key present? {}\n", .{map.contains(1)});

    // `response` tells us whether anything was found...
    if (!response.found_existing) {
        // ...so we can populate an (empty) list at that location...
        var list = std.ArrayList(u32).init(allocator);
        // This doesn't actually seem to work - see comment near the end of the function
        defer list.deinit();
        try map.put(1, list);
    }
    // And add a value to it
    try response.value_ptr.append(2);
    // For reasons I don't understand, `map.get(1).?.append(2)` doesn't work - the returned
    // pointer-to-ArrayList is immutable (`const`), thus preventing appending

    // Prove that it worked:
    print("The first value of the list is {}\n", .{map.get(1).?.items[0]});
    // I don't know why this is necessary, since I already called `defer list.deinit()` above -
    // but, without this, I get a memory leak reported
    map.get(1).?.deinit();
}
```

Note in particular line the comment after `const response = try map.getOrPut(1)`. There isn't any value "put" into the map!

Many thanks to the folks at [ziggit](https://ziggit.dev/t/whats-the-point-in-hashmap-getorput/7547) for helping me figure out that I was thinking too high-level about this - adding a key to a HashMap is _not_ a "free" operation, it requires hashing the key (and any associated deduplication of collisions), and reservation of space for the target value[^memory]. In particular, they helped me realize that the return of a `value_ptr` from `getOrPut` means that an optimization is possible in the code I wrote above - I can replace `try map.put(1, list)` (which would require hashing `1` _again_ to determine the target location) with `response.value_ptr.* = list`, "short-circuiting" that calculation for a performance boost.

Awesome! But - [engineers are from Missouri](https://history.howstuffworks.com/american-history/missouri-show-me-state.htm). I deeply appreciate the guidance, but I firmly believe that you don't really internalize a lesson (and shouldn't necessarily trust it) unless you've had it proven - ideally, until you've proven it to yourself. So, here we go!

```zig
const std = @import("std");
const print = std.debug.print;

// Yes, these are low - see discussion below
const TIMES_TO_RUN_A_SINGLE_TEST = 5;
const NUMBER_OF_TESTS_TO_RUN = 5;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Stolen from https://zig.guide/standard-library/random-numbers/
    var prng = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    const rand = prng.random();

    // I tried `= try allocator.alloc(u25, NUMBER_OF_TESTS_TO_RUN);`, and got `expected type '[5]u256', found '[]u256'`
    // :shrug:
    var pointer_based_times: [NUMBER_OF_TESTS_TO_RUN]u256 = undefined;
    for (0..NUMBER_OF_TESTS_TO_RUN - 1) |i| {
        pointer_based_times[i] = try timePointerBasedMethod(rand, allocator);
    }

    var non_pointer_based_times: [NUMBER_OF_TESTS_TO_RUN]u256 = undefined;
    for (0..NUMBER_OF_TESTS_TO_RUN - 1) |i| {
        non_pointer_based_times[i] = try timeNonPointerBasedMethod(rand, allocator);
    }

    print("Summary of pointer-based times: {}\n", .{summarizeTimes(pointer_based_times)});
    print("Summary of non-pointer-based times: {}\n", .{summarizeTimes(non_pointer_based_times)});
}

fn timePointerBasedMethod(rnd: std.Random, allocator: std.mem.Allocator) !u256 {
    var map = std.AutoHashMap(u32, std.ArrayList(u32)).init(allocator);
    defer map.deinit();
    const start_timestamp = std.time.nanoTimestamp();
    for (0..TIMES_TO_RUN_A_SINGLE_TEST - 1) |_| {
        const key = rnd.int(u32);
        const value = rnd.int(u32);
        const response = try map.getOrPut(key);
        if (!response.found_existing) {
            response.value_ptr.* = std.ArrayList(u32).init(allocator);
        }
        try response.value_ptr.append(value);
    }
    const time_elapsed = std.time.nanoTimestamp() - start_timestamp;
    var it = map.valueIterator();
    while (it.next()) |value| {
        value.deinit();
    }
    return try convertTou256(time_elapsed);
}

fn timeNonPointerBasedMethod(rnd: std.Random, allocator: std.mem.Allocator) !u256 {
    var map = std.AutoHashMap(u32, std.ArrayList(u32)).init(allocator);
    defer map.deinit();
    const start_timestamp = std.time.nanoTimestamp();
    for (0..TIMES_TO_RUN_A_SINGLE_TEST - 1) |_| {
        const key = rnd.int(u32);
        const value = rnd.int(u32);
        const response = try map.getOrPut(key);
        if (!response.found_existing) {
            try map.put(key, std.ArrayList(u32).init(allocator));
        }
        try response.value_ptr.append(value);
    }
    const time_elapsed = std.time.nanoTimestamp() - start_timestamp;
    var it = map.valueIterator();
    while (it.next()) |value| {
        value.deinit();
    }
    return try convertTou256(time_elapsed);
}

const ArithmeticError = error{NegativeTime};

fn convertTou256(n: i128) ArithmeticError!u256 {
    if (n < 0) {
        // This _should_ never happen!
        return ArithmeticError.NegativeTime;
    } else {
        return @intCast(n);
    }
}

// Plenty of other stats we could consider, like p90/p99, median, etc.
const Summary = struct {
    max: u256,
    mean: u256,
};

fn summarizeTimes(times: [NUMBER_OF_TESTS_TO_RUN]u256) Summary {
    var total_so_far: u256 = 0;
    var max_so_far: u256 = 0;
    // For some reason (probably to do with integer overflow :shrug:), I get the occasional time that is _wildly_ large -
    // like, 10^60 years big. I already spent an hour futzing with integer types trying to avoid this, to no avail - so
    // I'm just filtering out the nonsense instead to get usable data.
    var count_of_legal_times: usize = 0;
    for (times) |time| {
        if (time > 100000000) {
            continue;
        }
        total_so_far += time;
        if (time > max_so_far) {
            max_so_far = time;
        }
        count_of_legal_times += 1;
    }
    return Summary{ .max = max_so_far, .mean = @divFloor(total_so_far, count_of_legal_times) };
}
```

...aaaaand, unfortunately I don't have any convincing data to show. Sequential runs of this program gave inconsistent
results, with neither approach being clearly faster, but (anecdotally) _non_-pointer-based approach seeming to be faster
more often than not:

```
Summary of pointer-based times: test.Summary{ .max = 217000, .mean = 158000 }
Summary of non-pointer-based times: test.Summary{ .max = 138000, .mean = 138000 }
---
Summary of pointer-based times: test.Summary{ .max = 219000, .mean = 158500 }
Summary of non-pointer-based times: test.Summary{ .max = 139000, .mean = 138500 }
---
Summary of pointer-based times: test.Summary{ .max = 216000, .mean = 158000 }
Summary of non-pointer-based times: test.Summary{ .max = 140000, .mean = 139750 }
---
Summary of pointer-based times: test.Summary{ .max = 218000, .mean = 159000 }
Summary of non-pointer-based times: test.Summary{ .max = 278000, .mean = 175750 }
```

You'll note that the variables `TIMES_TO_RUN_A_SINGLE_TEST` and `NUMBER_OF_TESTS_TO_RUN` are super low, so these data are hardly statistically sound. I started out with `1000` and `50` - but experienced a Segmentation Fault (`aborting due to recursive panic`, with a code pointer into `lib/std/array_list.zig`), that I was unable to debug. Even values as low as `10` and `5` caused this issue. I hope I can figure this out to run a more scientific experiment.

Still, even with these low counts - it's surprising for the pointer-based approach to be pretty consistently _slower_. I suspect I'm doing something wrong in my test cases, since the explanation I was given seems intuitively sensible - "_finding the value-location_" twice is always going to be slower than finding it once. I wonder if it's possible that some other part of the test-setup (say, random number generation) dominates the time-spent, and so I'm not actually getting an accurate comparison of pointer-based vs. non-pointer-based interaction with Map Values. I'll try some further experiments in that direction.


[^advent-of-code]: you can see my solutions [here](https://gitea.scubbo.org/scubbo/advent-of-code-2024) - though, since I'd written zero lines of Zig before these challenges, and I've mostly been focused on achieving solutions quickly rather than optimally or maintainably, please don't judge me on Code Quality! 😆
[^rust]: which I used for [last year's Advent Of Code](https://github.com/scubbo/advent-of-code-2023)
[^comparison]: in brief: although I personally find the experience of writing in Systems Programming Languages to be cumbersome, I can absolutely see their value _when used appropriately_; and the mental workout of having to think about memory and efficiency will, I believe, make me a better programmer even in other languages. Sadly, in my professional life we are using GoLang in situations that it is highly unsuited for - specifically, performance-insensitive use-cases, where "_developing fast, in an easily understandable and changable way_" is much more important than "_executing fast_". Having acknowledged that System Programming has its place, however, I disagree with almost every design decision that Rob Pike and co. have made in GoLang - it's not "_bad because it is a Systems Programming Language_", it's "_a bad language that is a Systems Programming Language_". Thankfully, from what I have seen of Zig so far, I like it a _lot_ more!
[^running]: there are plenty of Zig playgrounds/"fiddles" where you can run this without installing Zig on your own system - [e.g.](https://zigfiddle.dev/?mi8GjtRPN50).
[^memory]: I might well have used the wrong terminology there - in particular, I think it's not _allocating_ memory in the `allocator.alloc` sense.
