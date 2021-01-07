const std = @import("std");
const warn = std.debug.warn;

usingnamespace (@import("language.zig"));

const stdout = std.io.getStdOut().outStream();

pub fn main() anyerror!void {
    const allocator = std.testing.allocator;
    const filepath = std.mem.span(std.os.argv[1]);

    const dirname = std.fs.path.dirname(filepath) orelse ".";
    const dir_fd = try std.os.open(dirname, 0, std.os.O_RDONLY);
    var dir = std.fs.Dir{ .fd = dir_fd };
    defer dir.close();

    var file = try dir.openFile(std.fs.path.basename(filepath), .{});
    defer file.close();

    const program = try file.readToEndAlloc(allocator, 1024 * 1000 * 1000);
    run(program);
}

fn run(program: []const u8) void {
    var registers = Registers{};
    var regs = @ptrCast([*]RSIZE, &registers);

    // var callstack = [_]u8{0} ** 1024;

    var alive = true;
    while (alive) {
        const opcode = program[registers.ip];
        // warn("pos: {}  ", .{registers.ip});
        const operation = Operations[opcode];
        // warn("{}\n", .{operation.name});

        const arg1 = program[registers.ip + 1];
        const arg2 = if (operation.len > 1) program[registers.ip + 2] else 0;
        const arg3 = if (operation.len > 2) program[registers.ip + 3] else 0;
        const arg4 = if (operation.len > 3) program[registers.ip + 4] else 0;

        switch (@intToEnum(Opcode, opcode)) {
            .set => {
                regs[arg1] = arg2;
            },
            .pop => {
                stdout.print("{}\n", .{regs[arg1]}) catch @panic("Error printing popped value");
            },
            .jmp => {
                jump(regs[arg1], &registers.ip);
                continue;
            },
            .gate => {
                if (regs[arg2] != regs[arg3]) {
                    jump(regs[arg1], &registers.ip);
                    continue;
                }
            },
            .cjmp => {
                if (regs[arg2] == regs[arg3]) {
                    jump(regs[arg1], &registers.ip);
                    continue;
                }
            },
            .cmp => {
                const result = regs[arg2] == regs[arg3];
                regs[arg1] = @boolToInt(result);
            },
            .xit => {
                warn("exiting with value: {}\n", .{regs[arg1]});
                alive = false;
                continue;
            },
            .add => {
                registers.ofl += @intCast(i2, @boolToInt(@addWithOverflow(RSIZE, regs[arg2], regs[arg3], &regs[arg1])));
            },
            .sub => {
                registers.ofl += @intCast(i2, @boolToInt(@subWithOverflow(RSIZE, regs[arg2], regs[arg3], &regs[arg1])));
            },
            .mul => {
                registers.ofl += @intCast(i2, @boolToInt(@mulWithOverflow(RSIZE, regs[arg2], regs[arg3], &regs[arg1])));
            },
            // else => {
            //     warn("instruction: {}\n", .{operation.name});
            //     @panic("unimplemented instruction");
            // },
        }
        registers.ip += operation.len + 1; // move instruction pointer to next opcode
        if (registers.ip > (program.len - 1)) {
            alive = false;
        }
    }
    warn("\nProgram complete.\n{}\n", .{registers});
}

fn jump(amount: RSIZE, ip: *usize) void {
    // warn("jumping {} from {}\n", .{ amount, ip.* });
    if (amount >= 0) {
        ip.* += @intCast(usize, amount);
    } else {
        ip.* -= @intCast(usize, (0 - amount));
    }
}

test "example program" {
    // const program = [_]u8{ 0, 0, 24, 1, 0 }; // set register a to 24; pop register a
    const program = [_]u8{
        @enumToInt(Opcode.add),
        @enumToInt(Register.a),
        1,
        2,

        @enumToInt(Opcode.pop),
        @enumToInt(Register.a),

        @enumToInt(Opcode.jmp),
        @enumToInt(Register.a),
        99,
        @enumToInt(Opcode.xit),
        3,
    }; // add two numbers and stores result in register a; pop register a; move instruction pointer to memory address located in register a;

    run(program[0..]);
}
