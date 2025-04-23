const std = @import("std");
const palloc = std.heap.page_allocator;
const print = std.debug.print;
const Date = @import("date_time.zig").Date;

pub fn main() !void {}

// sum in minimal units,
// persent is float, example 0.25 (25%)
fn calculateSimpleProffit(
    start_date: Date,
    months: u32,
    sum: u64,
    persent: f32,
) !u64 {
    const end_date = try start_date.shiftMonths(months);
    const date_chunks = try splitByYears(start_date, end_date, palloc);
    defer palloc.free(date_chunks);
    var total: f64 = 0;
    for (date_chunks, 0..) |chunk, idx| {
        const start = chunk.start;
        const end = chunk.end;
        var days: u32 = 0;
        if (idx == 0) {
            days = try start.daysBetween(&end);
        } else {
            days = try start.daysBetween(&end) + 1;
        }
        const days_in_year = end.year.days;
        const sum_float: f64 = @as(f64, @floatFromInt(sum));
        const days_float: f64 = @as(f64, @floatFromInt(days));
        const calculated_sum: f64 = (sum_float * persent * days_float) / @as(f64, @floatFromInt(days_in_year));
        total = total + calculated_sum;
    }
    return @intFromFloat(@round(total));
}

fn splitByYears(start_date: Date, end_date: Date, alloc: std.mem.Allocator) ![]DateChunk {
    const chunks_size = (end_date.year.number - start_date.year.number) + 1;
    var chunks: []DateChunk = try alloc.alloc(DateChunk, chunks_size);
    if (end_date.year.number == start_date.year.number) {
        const single_chunk = DateChunk{
            .start = try Date.init(start_date.year.number, start_date.month.number, start_date.day),
            .end = try Date.init(end_date.year.number, end_date.month.number, end_date.day),
        };
        chunks[0] = single_chunk;
        return chunks;
    }
    var initial_year = start_date.year.number;
    var i: u32 = 0;
    const first_chank_idx = 0;
    const last_chank_idx = chunks_size - 1;
    while (initial_year <= end_date.year.number) {
        if (i == first_chank_idx) {
            chunks[i] = DateChunk{
                .start = try Date.init(initial_year, start_date.month.number, start_date.day),
                .end = try Date.init(initial_year, 12, 31),
            };
        } else if (i == last_chank_idx) {
            chunks[i] = DateChunk{
                .end = try Date.init(initial_year, end_date.month.number, end_date.day),
                .start = try Date.init(initial_year, 1, 1),
            };
        } else {
            chunks[i] = DateChunk{
                .end = try Date.init(initial_year, 12, 31),
                .start = try Date.init(initial_year, 1, 1),
            };
        }
        i = i + 1;
        initial_year = initial_year + 1;
    }
    return chunks;
}

const DateChunk = struct {
    start: Date,
    end: Date,
};

test "should split dates to chanks" {
    const alloc = std.testing.allocator;
    const single_chunk = try splitByYears(
        try Date.init(2025, 4, 16),
        try Date.init(2025, 9, 25),
        alloc,
    );

    try std.testing.expectEqual(1, single_chunk.len);
    alloc.free(single_chunk);

    const multiple_chunks = try splitByYears(
        try Date.init(2025, 4, 16),
        try Date.init(2028, 5, 25),
        alloc,
    );

    try std.testing.expectEqual(4, multiple_chunks.len);
    try std.testing.expect(multiple_chunks[0].start.equals(&try Date.init(2025, 4, 16)));
    try std.testing.expect(multiple_chunks[0].end.equals(&try Date.init(2025, 12, 31)));
    try std.testing.expect(multiple_chunks[1].start.equals(&try Date.init(2026, 1, 1)));
    try std.testing.expect(multiple_chunks[1].end.equals(&try Date.init(2026, 12, 31)));
    try std.testing.expect(multiple_chunks[2].start.equals(&try Date.init(2027, 1, 1)));
    try std.testing.expect(multiple_chunks[2].end.equals(&try Date.init(2027, 12, 31)));
    try std.testing.expect(multiple_chunks[3].start.equals(&try Date.init(2028, 1, 1)));
    try std.testing.expect(multiple_chunks[3].end.equals(&try Date.init(2028, 5, 25)));
    alloc.free(multiple_chunks);
}

test "should calculate profit considering a leap year" {
    const same_year_profit: u64 = try calculateSimpleProffit(
        try Date.init(2025, 4, 23),
        8,
        100500,
        0.21,
    );

    try std.testing.expectEqual(14109, same_year_profit);

    const several_years_profit: u64 = try calculateSimpleProffit(
        try Date.init(2025, 4, 23),
        32,
        222222,
        0.205,
    );

    try std.testing.expectEqual(121565, several_years_profit);

    const with_leap_year_profit: u64 = try calculateSimpleProffit(
        try Date.init(2025, 4, 23),
        44,
        222222,
        0.175,
    );

    try std.testing.expectEqual(142666, with_leap_year_profit);

    const date_start_on_new_year: u64 = try calculateSimpleProffit(
        try Date.init(2025, 12, 31),
        60,
        333333,
        0.134,
    );

    try std.testing.expectEqual(223_333, date_start_on_new_year);
}
