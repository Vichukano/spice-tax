const std = @import("std");
const initial_year = 1970;
const max_days_in_month = 31;
const max_month = 12;

// delimeter
//----------

//----------API----------
pub const Date = struct {
    year: Year,
    month: Month,
    day: u8,

    pub fn init(year: u32, month: u8, day: u8) DateValidationError!Date {
        const y = try Year.init(year);
        const m = try Month.init(month, y.is_leap);
        try validateDay(day, &m, &y);
        return Date{ .year = y, .month = m, .day = day };
    }

    pub fn isLeapYear(self: *const Date) bool {
        return self.year.is_leap;
    }

    pub fn equals(self: *const Date, other: *const Date) bool {
        return self.year.equals(&other.year) and self.month.equals(&other.month) and self.day == other.day;
    }

    pub fn toString(self: *const Date, allocator: std.mem.Allocator) []const u8 {
        return std.fmt.allocPrint(
            allocator,
            "Date(year = {s}, month = {s}, day = {d})",
            .{ self.year.toString(allocator), self.month.toString(allocator), self.day },
        ) catch "failed create toString of Date struct";
    }

    pub fn compare(self: *const Date, other: *const Date) DateOrder {
        if (self.equals(other)) {
            return DateOrder.Equals;
        }
        if (self.year.number < other.year.number) {
            return DateOrder.Less;
        }
        if (self.year.number > other.year.number) {
            return DateOrder.Greater;
        }
        if (self.month.number < other.month.number) {
            return DateOrder.Less;
        }
        if (self.month.number > other.month.number) {
            return DateOrder.Greater;
        }
        if (self.day < other.day) {
            return DateOrder.Less;
        }
        return DateOrder.Greater;
    }

    pub fn shiftDays(self: *const Date, days_to_shift: u32) DateValidationError!Date {
        var curr_year = self.year;
        var curr_month = self.month;
        var curr_day = self.day;
        var i = days_to_shift;
        while (i > 0) {
            if (curr_day < curr_month.days) {
                curr_day = curr_day + 1;
            } else {
                curr_day = 1;
                if (curr_month.number == 12) {
                    curr_year = try Year.init(curr_year.number + 1);
                    curr_month = try Month.init(1, curr_year.is_leap);
                } else {
                    curr_month = try Month.init(curr_month.number + 1, curr_year.is_leap);
                }
            }
            i = i - 1;
        }
        return try Date.init(curr_year.number, curr_month.number, curr_day);
    }

    pub fn shiftMonths(self: *const Date, months_to_shift: u32) DateValidationError!Date {
        var curr_year = self.year;
        var curr_month = self.month;
        var curr_day = self.day;
        var i = months_to_shift;
        while (i > 0) {
            if (curr_month.number == 12) {
                curr_year = try Year.init(curr_year.number + 1);
                curr_month = try Month.init(1, curr_year.is_leap);
            } else {
                curr_month = try Month.init(curr_month.number + 1, curr_year.is_leap);
            }
            i = i - 1;
        }
        if (curr_day > curr_month.days) {
            curr_day = curr_month.days;
        }
        return try Date.init(curr_year.number, curr_month.number, curr_day);
    }

    pub fn shiftYears(self: *const Date, years_to_shift: u32) DateValidationError!Date {
        var curr_year = self.year;
        var curr_month = self.month;
        var curr_day = self.day;
        var i = years_to_shift;
        while (i > 0) {
            curr_year = try Year.init(curr_year.number + 1);
            curr_month = try Month.init(curr_month.number, curr_year.is_leap);
            i = i - 1;
        }
        if (curr_day > curr_month.days) {
            curr_day = curr_month.days;
        }
        return try Date.init(curr_year.number, curr_month.number, curr_day);
    }

    // Calculate number of days between two dates.
    // Self date uninclusive, other date inclusive.
    pub fn daysBetween(self: *const Date, other: *const Date) DateValidationError!u32 {
        var curr_year = self.year;
        var curr_month = self.month;
        var curr_day = self.day;
        var days_count: u32 = 0;
        var isDatesEquals = curr_year.number == other.year.number and curr_month.number == other.month.number and curr_day == other.day;
        while (!isDatesEquals) {
            days_count = days_count + 1;
            if (curr_day < curr_month.days) {
                curr_day = curr_day + 1;
            } else {
                curr_day = 1;
                if (curr_month.number == 12) {
                    curr_year = try Year.init(curr_year.number + 1);
                    curr_month = try Month.init(1, curr_year.is_leap);
                } else {
                    curr_month = try Month.init(curr_month.number + 1, curr_year.is_leap);
                }
            }
            isDatesEquals = curr_year.number == other.year.number and curr_month.number == other.month.number and curr_day == other.day;
        }
        return days_count;
    }

    fn validateDay(day_number: u8, month: *const Month, year: *const Year) DateValidationError!void {
        if (day_number > max_days_in_month) {
            return DateValidationError.InvalidDayFormath;
        }
        if (month.number == 2) {
            if (year.is_leap) {
                if (day_number > 29) {
                    return DateValidationError.InvalidDayFormath;
                }
            } else {
                if (day_number > 28) {
                    return DateValidationError.InvalidDayFormath;
                }
            }
        }
    }
};

const Year = struct {
    number: u32,
    is_leap: bool,
    days: u16,

    fn init(year: u32) DateValidationError!Year {
        try validateYear(year);
        const is_leap = (year % 4 == 0 and year % 100 != 0) or (year % 400 == 0);
        const days: u16 = if (is_leap) 366 else 365;
        return Year{ .number = year, .is_leap = is_leap, .days = days };
    }

    fn validateYear(year: u32) DateValidationError!void {
        if (year <= initial_year) {
            return DateValidationError.InvalidYearFormath;
        }
    }

    fn equals(self: *const Year, other: *const Year) bool {
        return self.number == other.number and self.is_leap == other.is_leap and self.days == other.days;
    }

    fn toString(self: *const Year, allocator: std.mem.Allocator) []const u8 {
        return std.fmt.allocPrint(
            allocator,
            "Year(number = {d}, is_leap = {}, days = {d})",
            .{ self.number, self.is_leap, self.days },
        ) catch "failed create toString of Year struct";
    }
};

const Month = struct {
    name: []const u8,
    number: u8,
    days: u8,

    fn init(number: u8, is_leap_year: bool) DateValidationError!Month {
        try validateMonth(number);
        if (number == 2) {
            if (is_leap_year) {
                return all_months[12];
            }
        }
        return all_months[number - 1];
    }

    fn validateMonth(number: u8) DateValidationError!void {
        if (number <= 0) {
            return DateValidationError.InvalidMonthFormath;
        }
        if (number > max_month) {
            return DateValidationError.InvalidMonthFormath;
        }
    }

    fn equals(self: *const Month, other: *const Month) bool {
        return self.number == other.number and std.mem.eql(u8, self.name, other.name);
    }

    fn toString(self: *const Month, allocator: std.mem.Allocator) []const u8 {
        return std.fmt.allocPrint(
            allocator,
            "Month(name = {s}, number = {d}, days = {d})",
            .{ self.name, self.number, self.days },
        ) catch "failed create toString of Month struct";
    }
};

pub const DateOrder = enum {
    Less,
    Greater,
    Equals,
};

//----------API-END----------

const all_months = [13]Month{
    .{ .name = "January", .number = 1, .days = 31 },
    .{ .name = "February", .number = 2, .days = 28 },
    .{ .name = "March", .number = 3, .days = 31 },
    .{ .name = "April", .number = 4, .days = 30 },
    .{ .name = "May", .number = 5, .days = 31 },
    .{ .name = "June", .number = 6, .days = 30 },
    .{ .name = "July", .number = 7, .days = 31 },
    .{ .name = "August", .number = 8, .days = 31 },
    .{ .name = "Septempber", .number = 9, .days = 30 },
    .{ .name = "October", .number = 10, .days = 31 },
    .{ .name = "November", .number = 11, .days = 30 },
    .{ .name = "December", .number = 12, .days = 31 },
    .{ .name = "February", .number = 2, .days = 29 },
};

const DateValidationError = error{
    InvalidYearFormath,
    InvalidMonthFormath,
    InvalidDayFormath,
};

//----------TESTS----------//

test "should validate date" {
    const invalid_year = Date.init(10, 10, 10);
    const invalid_month = Date.init(2025, 13, 10);
    const invalid_days = Date.init(2025, 10, 100);
    const invalid_days_in_non_leap_feb = Date.init(2025, 2, 29);

    try std.testing.expectError(DateValidationError.InvalidYearFormath, invalid_year);
    try std.testing.expectError(DateValidationError.InvalidMonthFormath, invalid_month);
    try std.testing.expectError(DateValidationError.InvalidDayFormath, invalid_days);
    try std.testing.expectError(DateValidationError.InvalidDayFormath, invalid_days_in_non_leap_feb);

    _ = try Date.init(2025, 12, 31);
    _ = try Date.init(2024, 2, 29);
}

test "leap year testing" {
    const non_leap = try Date.init(2025, 2, 10);
    const prev_leap = try Date.init(2024, 3, 19);
    const next_leap = try Date.init(2028, 4, 21);

    try std.testing.expectEqual(false, non_leap.isLeapYear());
    try std.testing.expectEqual(true, prev_leap.isLeapYear());
    try std.testing.expectEqual(true, next_leap.isLeapYear());
}

test "same date should be equals" {
    const one = try Date.init(2025, 5, 25);
    const two = try Date.init(2025, 5, 25);
    const three = try Date.init(2026, 8, 13);

    try std.testing.expect(one.equals(&two));
    try std.testing.expect(two.equals(&two));
    try std.testing.expect(two.equals(&one));
    try std.testing.expect(!one.equals(&three));
}

test "should shift days correctly" {
    const origin = try Date.init(2025, 4, 20);

    try std.testing.expect((try origin.shiftDays(300)).equals(&try Date.init(2026, 2, 14)));
    try std.testing.expect((try origin.shiftDays(150)).equals(&try Date.init(2025, 9, 17)));
    try std.testing.expect((try origin.shiftDays(20)).equals(&try Date.init(2025, 5, 10)));
    try std.testing.expect((try origin.shiftDays(100500)).equals(&try Date.init(2300, 6, 18)));
    try std.testing.expect((try origin.shiftDays(600)).equals(&try Date.init(2026, 12, 11)));
}

test "should shift months correctly" {
    const origin = try Date.init(2025, 4, 20);
    const last_december = try Date.init(2025, 12, 31);
    const leap_february = try Date.init(2024, 2, 29);
    const last_december_before_leap = try Date.init(2023, 12, 31);

    try std.testing.expect((try origin.shiftMonths(3)).equals(&try Date.init(2025, 7, 20)));
    try std.testing.expect((try origin.shiftMonths(300)).equals(&try Date.init(2050, 4, 20)));
    try std.testing.expect((try origin.shiftMonths(1050)).equals(&try Date.init(2112, 10, 20)));
    try std.testing.expect((try last_december.shiftMonths(2)).equals(&try Date.init(2026, 2, 28)));
    try std.testing.expect((try leap_february.shiftMonths(3)).equals(&try Date.init(2024, 5, 29)));
    try std.testing.expect((try last_december_before_leap.shiftMonths(2)).equals(&try Date.init(2024, 2, 29)));
}

test "should shift years correctly" {
    const origin = try Date.init(2025, 3, 31);
    const february_leap = try Date.init(2024, 2, 29);

    try std.testing.expect((try origin.shiftYears(3)).equals(&try Date.init(2028, 3, 31)));
    try std.testing.expect((try february_leap.shiftYears(1)).equals(&try Date.init(2025, 2, 28)));
}

test "count days between dates" {
    const origin = try Date.init(2025, 3, 31);

    try std.testing.expectEqual(0, try origin.daysBetween(&try Date.init(2025, 3, 31)));
    try std.testing.expectEqual(1, try origin.daysBetween(&try Date.init(2025, 4, 1)));
    try std.testing.expectEqual(999, try origin.daysBetween(&try Date.init(2027, 12, 25)));
    try std.testing.expectEqual(100500, try origin.daysBetween(&try Date.init(2300, 5, 29)));
    try std.testing.expectEqual(100500, try (try Date.init(2025, 4, 20)).daysBetween(&try Date.init(2300, 6, 18)));
    try std.testing.expectEqual(365, try (try Date.init(2025, 1, 1)).daysBetween(&try Date.init(2026, 1, 1)));
    try std.testing.expectEqual(366, try (try Date.init(2024, 1, 1)).daysBetween(&try Date.init(2025, 1, 1)));
}

test "compare two dates" {
    const origin = try Date.init(2025, 3, 30);

    try std.testing.expectEqual(DateOrder.Equals, origin.compare(&try Date.init(2025, 3, 30)));
    try std.testing.expectEqual(DateOrder.Less, origin.compare(&try Date.init(2026, 3, 30)));
    try std.testing.expectEqual(DateOrder.Less, origin.compare(&try Date.init(2025, 4, 30)));
    try std.testing.expectEqual(DateOrder.Less, origin.compare(&try Date.init(2025, 3, 31)));
    try std.testing.expectEqual(DateOrder.Greater, origin.compare(&try Date.init(2021, 3, 31)));
    try std.testing.expectEqual(DateOrder.Greater, origin.compare(&try Date.init(2025, 2, 28)));
    try std.testing.expectEqual(DateOrder.Greater, origin.compare(&try Date.init(2025, 3, 29)));
}
