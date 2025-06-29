const std = @import("std");
const palloc = std.heap.page_allocator;
const print = std.debug.print;
const writer = std.io.getStdOut().writer();
const reader = std.io.getStdIn().reader();
const Date = @import("date_time.zig").Date;
const calc = @import("calculations.zig");
const start_message =
    \\##############################################################################
    \\##   Депозитный калькулятор приветсвует тебя!                               ##
    \\##   Я помогу тебе расчитать прибыль по простым и сложным депозитам.        ##
    \\##   Просто следуй инструкциям и последовательно передавай мне параметры.   ##
    \\##   Для завершения введи 'х'/'выход'/'exit' в любом диалоговом окне ввода. ##
    \\##############################################################################
;
const exit_markers = [4][]const u8{ "x", "х", "выход", "exit" };
const exit_message = "\nПрограмма завершена\n";

pub fn main() !void {
    try info();
    var buffer: [1024]u8 = undefined;
    try writeInfo(writer, "Дата", "Введите дату открытия депозита в формате yyyy-mm-dd. Пример: 2025-06-06\n\nДата: ");
    const date_input = try readInput(reader, &buffer, palloc);
    defer palloc.free(date_input);
    if (checkExit(date_input)) {
        try exit();
        return;
    }
    const date = Date.fromISO(date_input) catch {
        try writer.writeAll("Не верный формат даты. Дата должна быть в формате yyyy-mm-dd. Пример: 2025-06-06\n");
        try exit();
        return;
    };
    try writeInfo(writer, "Сумма", "Введите сумму. Допустимо указание минимальных единиц через ',' или '.'. Пример: 100500, 2025,15, 33355.99\n\nСумма: ");
    const sum_input = try readInput(reader, &buffer, palloc);
    defer palloc.free(sum_input);
    if (checkExit(sum_input)) {
        try exit();
        return;
    }
    const kopeck = parseToKopeck(sum_input) catch {
        try writer.writeAll("Не верный формат суммы.\n");
        try exit();
        return;
    };
    try writeInfo(writer, "Процент", "Введите % по депозиту. Пример: 13, 25.6, 0.15\n\nПроцент: ");
    const persent_input = try readInput(reader, &buffer, palloc);
    defer palloc.free(persent_input);
    if (checkExit(persent_input)) {
        try exit();
        return;
    }
    const persent_parsed: f32 = std.fmt.parseFloat(f32, persent_input) catch {
        try writer.writeAll("Не верный формат процента\n");
        try exit();
        return;
    };
    const persent_normalized: f32 = persent_parsed / @as(f32, @floatFromInt(100));
    try writeInfo(writer, "Период", "Введите период по депозиту: Годы - 'г', месяцы - 'м'.\n\nПериод: ");
    const period_defenition_input = try readInput(reader, &buffer, palloc);
    defer palloc.free(period_defenition_input);
    if (checkExit(period_defenition_input)) {
        try exit();
        return;
    }
    if (!isPeriodDefinitonValid(period_defenition_input)) {
        try writer.print("Не верный период, должен быть 'г' или 'м'. Вы ввели: {s}", .{period_defenition_input});
        try exit();
        return;
    }
    try writeInfo(writer, "Срок", "Введите срок по депозиту целым числом. Пример: 6\n\nСрок: ");
    const period_input = try readInput(reader, &buffer, palloc);
    defer palloc.free(period_input);
    if (checkExit(persent_input)) {
        try exit();
        return;
    }
    const period_defenition_formatted = if (std.mem.eql(u8, "г", period_defenition_input)) "года/лет" else "месяца/месяцев";
    try writeInfo(writer, "Капитализация", "По проценту предусмотрена капитализация?\n'д' - ежедневная,\n'м' - ежемесячная,\n'г' - годовая.\nЛюбое другое значение, если не предусморена.\n\nВвод: ");
    const capitalization_input = try readInput(reader, &buffer, palloc);
    defer palloc.free(capitalization_input);
    const cap_period = capitalizationPeriod(capitalization_input);
    const cap_period_fomatted = switch (cap_period) {
        .None => "без капитализации",
        .Day => "ежедневная",
        .Year => "ежегодная",
        .Month => "ежемесячная",
    };
    try writer.writeAll("\n##########################################################\n\n");
    const persent_formatted = persent_normalized * 100;
    try writer.print(
        "Вы ввели: дата открытия: {s}\nСумма: {s}\nПроцент: {d}%\nСрок: {s} {s}\nКапитализация: {s}\n\nВведенные данные верны? 'дa/д' - для подтверждения.\n\nВвод: ",
        .{ date_input, sum_input, persent_formatted, period_input, period_defenition_formatted, cap_period_fomatted },
    );
    const confirm_input = try readInput(reader, &buffer, palloc);
    defer palloc.free(confirm_input);
    if (!isInputConfirmed(confirm_input)) {
        try exit();
        return;
    }
    // read input finished there
    const period_int: u32 = try std.fmt.parseInt(u32, period_input, 10);
    const months: u32 = if (std.mem.eql(u8, "г", period_defenition_input)) period_int * @as(u32, 12) else period_int;
    switch (cap_period) {
        .None => {
            const simpte_profit = try calc.calculateSimpleProffit(date, months, kopeck, persent_normalized);
            try printProfit(writer, simpte_profit, palloc);
        },
        else => {
            const compex_profit = try calc.calculateComppexProfit(date, months, kopeck, persent_normalized, cap_period);
            try printProfit(writer, compex_profit, palloc);
        },
    }
    try exit();
}

fn info() !void {
    try writer.print("{s}\n\n", .{start_message});
}

fn exit() !void {
    try writer.writeAll(exit_message);
}

fn writeInfo(
    writer_stdout: anytype,
    title: []const u8,
    text: []const u8,
) !void {
    try writer_stdout.print("\n####################################\n               {s}\n####################################\n\n", .{title});
    try writer_stdout.writeAll(text);
}

fn readInput(
    input_reader: anytype,
    buffer: []u8,
    alloc: std.mem.Allocator,
) ![]const u8 {
    const input = try input_reader.readUntilDelimiterOrEof(buffer, '\n') orelse "";
    const content = try alloc.alloc(u8, input.len);
    std.mem.copyForwards(u8, content, input);
    return content;
}

fn checkExit(input: []const u8) bool {
    for (exit_markers) |marker| {
        if (std.mem.eql(u8, marker, input)) {
            return true;
        }
    }
    return false;
}

fn isPeriodDefinitonValid(input: []const u8) bool {
    const is_year = std.mem.eql(u8, "г", input);
    const is_month = std.mem.eql(u8, "м", input);
    return (is_year or is_month);
}

fn isInputConfirmed(input: []const u8) bool {
    const is_y = std.mem.eql(u8, "д", input);
    const is_yes = std.mem.eql(u8, "да", input);
    return (is_y or is_yes);
}

fn capitalizationPeriod(input: []const u8) calc.CapitalisationPeriod {
    const is_day = std.mem.eql(u8, "д", input);
    const is_month = std.mem.eql(u8, "м", input);
    const is_year = std.mem.eql(u8, "г", input);
    if (is_day) {
        return calc.CapitalisationPeriod.Day;
    }
    if (is_month) {
        return calc.CapitalisationPeriod.Month;
    }
    if (is_year) {
        return calc.CapitalisationPeriod.Year;
    }
    return calc.CapitalisationPeriod.None;
}

fn parseToKopeck(input: []const u8) !u64 {
    var dot_index: usize = input.len;
    var found_separator = false;
    for (input, 0..) |c, i| {
        if (c == '.' or c == ',') {
            if (found_separator) return error.InvalidFormat;
            dot_index = i;
            found_separator = true;
        } else if (c < '0' or c > '9') {
            return error.InvalidCharacter;
        }
    }
    if (!found_separator) {
        return try std.fmt.parseInt(u64, input, 10) * 100;
    }
    const int_part = input[0..dot_index];
    const frac_part = input[dot_index + 1 ..];
    if (frac_part.len == 0 or frac_part.len > 2) return error.InvalidFraction;
    var frac_buf: [2]u8 = .{ '0', '0' };
    std.mem.copyForwards(u8, frac_buf[0..frac_part.len], frac_part);
    const int_val = std.fmt.parseInt(u64, int_part, 10) catch return error.InvalidInteger;
    const frac_val = std.fmt.parseInt(u64, &frac_buf, 10) catch return error.InvalidFraction;
    return int_val * 100 + frac_val;
}

fn printProfit(
    writer_stdout: anytype,
    profit_info: calc.ProfitInfo,
    allocator: std.mem.Allocator,
) !void {
    const end_sum = try formatAmount(profit_info.end_sum, allocator);
    const start_sum = try formatAmount(profit_info.start_sum, allocator);
    const delta = try formatAmount(profit_info.delta, allocator);
    const tax = profit_info.tax * 100.0;
    const ear = profit_info.effective_tax * 100.0;
    const start_date = profit_info.start_date;
    const end_date = profit_info.end_date;
    defer allocator.free(end_sum);
    defer allocator.free(start_sum);
    defer allocator.free(delta);
    try writer_stdout.writeAll("\n##########################################################\n\n");
    try writer_stdout.print("Дата открытия депозита:                {d}-{d}-{d}\n", .{ start_date.year.number, start_date.month.number, start_date.day });
    try writer_stdout.print("Дата закрытия депозита:                {d}-{d}-{d}\n", .{ end_date.year.number, end_date.month.number, end_date.day });
    try writer_stdout.print("Сумма открытия депозита:               {s}\n", .{start_sum});
    try writer_stdout.print("Сумма на конец депозита:               {s}\n", .{end_sum});
    try writer_stdout.print("Прибыль по депозиту составит:          {s}\n", .{delta});
    try writer_stdout.print("Базовая процентная ставка:             {d:.2}%\n", .{tax});
    try writer_stdout.print("Эффективная процентная ставка:         {d:.2}%\n", .{ear});
    try writer_stdout.writeAll("\n##########################################################\n");
}

fn formatAmount(
    amount: u64,
    allocator: std.mem.Allocator,
) ![]const u8 {
    const rubles = amount / 100;
    const kopecks = amount % 100;
    const rubles_str = try std.fmt.allocPrint(allocator, "{}", .{rubles});
    const kopecks_str = try std.fmt.allocPrint(allocator, "{:0>2}", .{kopecks}); // два символа, с ведущим 0
    return try std.mem.concat(allocator, u8, &[_][]const u8{ rubles_str, ",", kopecks_str });
}
