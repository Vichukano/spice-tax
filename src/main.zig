const std = @import("std");
const palloc = std.heap.page_allocator;
const print = std.debug.print;
const writer = std.io.getStdOut().writer();
const reader = std.io.getStdIn().reader();
const Date = @import("date_time.zig").Date;
const start_message =
    \\##############################################################################
    \\##   Депозитный калькулятор приветсвует тебя!                               ##
    \\##   Я помогу тебе расчитать прибыль по простым и сложным депозитам.        ##
    \\##   Просто следуй инструкциям и последовательно передавай мне параметры.   ##
    \\##   Для завершения введи 'х' в любом диалоговом окне ввода.                ##
    \\##############################################################################
;
const exit_char = "х";
const exit_message = "Программа завершена\n";

pub fn main() !void {
    try info();
    var buffer: [1024]u8 = undefined;
    try writer.writeAll("Введите дату открытия депозита в формате yyyy-mm-dd. Пример: 2025-06-06:\n");
    const date_input = try readInput(reader, &buffer, palloc);
    defer palloc.free(date_input);
    if (std.mem.eql(u8, date_input, exit_char)) {
        try exit();
        return;
    }
    try writer.writeAll("Введите сумму депозита целым числом в копейках:\n");
    const sum_input = try readInput(reader, &buffer, palloc);
    defer palloc.free(sum_input);
    if (std.mem.eql(u8, sum_input, exit_char)) {
        try exit();
        return;
    }
    try writer.writeAll("Введите процент по депозиту целым числом. Пример: 13\n");
    const persent_input = try readInput(reader, &buffer, palloc);
    defer palloc.free(persent_input);
    if (std.mem.eql(u8, persent_input, exit_char)) {
        try exit();
        return;
    }
    try writer.writeAll("Введите срок по депозиту целым числом. Пример: 6\n");
    const period_input = try readInput(reader, &buffer, palloc);
    defer palloc.free(period_input);
    if (std.mem.eql(u8, period_input, exit_char)) {
        try exit();
        return;
    }
    try writer.print("Вы ввели: дата открытия: {s}, сумма: {s}, процент: {s}, срок: {s}\n", .{ date_input, sum_input, persent_input, period_input });
    try exit();
}

fn info() !void {
    try writer.print("{s}\n\n", .{start_message});
}

fn exit() !void {
    try writer.writeAll(exit_message);
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
