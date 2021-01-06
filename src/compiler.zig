const std = @import("std");
const warn = std.debug.warn;

usingnamespace (@import("language.zig"));

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var args = std.process.args();
    _ = args.skip(); // skip arg[0], i.e. our program's name

    if (args.next(allocator)) |err_or_arg| {
        const filepath = try err_or_arg;
        defer allocator.free(filepath);
        warn("compiling {}\n", .{filepath});
        try compile_and_save(allocator, filepath);
    } else {
        warn("compiler requires a file path to operate on\n", .{});
        std.os.exit(2);
    }
}

fn compile_and_save(allocator: *std.mem.Allocator, filepath: []u8) !void {
    const fd = try std.os.open(filepath, 0, std.os.O_RDONLY);
    var file = std.fs.File{ .handle = fd };
    defer file.close();

    var buffer = [_]u8{0} ** 100;
    var read = try file.read(buffer[0..]);
    var file_contents = try allocator.alloc(u8, read);
    defer allocator.free(file_contents);
    std.mem.copy(u8, file_contents, buffer[0..read]);
    while (read != 0) {
        read = try file.read(buffer[0..]);
        if (read == 0) break;

        file_contents = try allocator.resize(file_contents, file_contents.len + read);
        // Copy buffer into the end of file_contents
        std.mem.copy(u8, file_contents[file_contents.len - read ..], buffer[0..read]);
    }

    var output = try compile(allocator, file_contents);
    defer allocator.free(output);

    const cwd = std.fs.cwd();
    var out_file = try cwd.createFile("a.out", .{});
    defer out_file.close();
    try out_file.writeAll(output);
}

fn compile(allocator: *std.mem.Allocator, data: []const u8) ![]u8 {
    var token_buffer = try allocator.alloc([]u8, data.len);
    defer allocator.free(token_buffer);
    const tokens = findTokens(data, token_buffer);

    var buffer = try allocator.alloc(u8, tokens.len);
    var buf_pos: usize = 0;

    var args: u8 = 0; // remaining args of current operation
    var operation: Operation = undefined;

    errdefer {
        warn("operation {}\n", .{operation});
        warn("remaining args {}\n", .{args});
        warn("tokens parsed {}\n", .{buf_pos});
    }

    for (tokens) |token| {
        if (args == 0) {
            const opcode = enumFromName(Opcode, token) catch |err| {
                warn("Unknown {} name \"{}\"\n", .{ @typeName(Opcode), token });
                return err;
            };
            buffer[buf_pos] = opcode;
            operation = Operations[opcode];
            args = operation.len;
        } else {
            const arg_type = operation.args[operation.len - args];
            buffer[buf_pos] = parseToken(token, arg_type) catch |err| {
                warn("Error parsing token '{}' as type '{}'\n", .{ token, arg_type });
                return err;
            };
            args -= 1;
        }
        buf_pos += 1;
    }

    return buffer;
}

test "compile" {
    const allocator = std.testing.allocator;
    const expected_program = [_]u8{
        @enumToInt(Opcode.set),
        @enumToInt(Register.b),
        100,
        @enumToInt(Opcode.pop),
        @enumToInt(Register.c),
    };
    const example = " set b 100 \n pop c ";
    const program = try compile(allocator, example[0..]);
    defer allocator.free(program);

    printProgram(program);

    for (expected_program) |_, index| {
        std.testing.expectEqual(expected_program[index], program[index]);
    }
}

fn printProgram(program: []const u8) void {
    warn("\n", .{});
    for (program) |i| {
        warn("{}, ", .{i});
    }
    warn("\n", .{});
}

/// Takes a string, returns a single u8 that represents it for use in our interpreter.
fn parseToken(token: []const u8, type_: ArgType) !u8 {
    switch (type_) {
        .reg => {
            return try enumFromName(Register, token);
        },
        .int => {
            return try std.fmt.parseInt(WORD, token, 10);
        },
    }
}

/// Takes an operation's name and returns its associated opcode
fn enumFromName(comptime T: type, name: []const u8) !u8 {
    if (std.meta.stringToEnum(T, name)) |e| {
        return @enumToInt(e);
    }
    return error.UnknownToken;
}

fn findTokens(data: []const u8, buffer: [][]const u8) [][]const u8 {
    var pos: usize = 0; // next token goes at this index of buffer

    var token_start: usize = 0;
    var active_token = false;
    for (data) |char, index| {
        if (active_token) {
            if (isWhitespace(char)) {
                buffer[pos] = data[token_start..index];
                pos += 1;
                active_token = false;
            }
        } else {
            if (!isWhitespace(char)) {
                token_start = index;
                active_token = true;
            }
        }
    }
    return buffer[0..pos];
}

const whitespace = [_]u8{
    ' ',
    '\n',
    '\t',
};
fn isWhitespace(char: u8) bool {
    for (whitespace) |w| {
        if (char == w) return true;
    }
    return false;
}
