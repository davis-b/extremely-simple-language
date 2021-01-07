pub const RSIZE = i32; // Register size
pub const WORD = u8; // Data that gets imbedded directly into binary

pub const Operation = struct {
    name: []const u8,
    len: u8,
    args: []const ArgType,
};

pub const ArgType = enum {
    reg,
    int,
};

pub const Operations = [_]Operation{
    .{ .name = "set", .len = 2, .args = &[_]ArgType{ .reg, .int } }, // set register at arg1 to value at arg2
    .{ .name = "pop", .len = 1, .args = &[_]ArgType{.reg} }, // pop value in register at arg1
    .{ .name = "xit", .len = 1, .args = &[_]ArgType{.reg} }, // exit program, returning value in register arg1

    .{ .name = "jmp", .len = 1, .args = &[_]ArgType{.reg} }, // move instruction pointer by value in register arg1
    .{ .name = "cjmp", .len = 3, .args = &[_]ArgType{ .reg, .reg, .reg } }, // conditional jump. jmp if reg2 is equal to reg3
    .{ .name = "gate", .len = 3, .args = &[_]ArgType{ .reg, .reg, .reg } }, // conditional jump. jmp if reg2 is not equal to reg3
    .{ .name = "cmp", .len = 3, .args = &[_]ArgType{ .reg, .reg, .reg } }, // compare reg2 with reg3, put result in reg1

    // Math operations. All results are stored in register1 unless otherwise specified.
    // These operations can set the overflow register.
    .{ .name = "add", .len = 3, .args = &[_]ArgType{ .reg, .reg, .reg } }, // add
    .{ .name = "sub", .len = 3, .args = &[_]ArgType{ .reg, .reg, .reg } }, // subtract; reg2 - reg3
    .{ .name = "mul", .len = 3, .args = &[_]ArgType{ .reg, .reg, .reg } }, // multiply
};

pub const Opcode = enum(u8) {
    set,
    pop,
    xit,

    jmp,
    cjmp,
    gate,
    cmp,

    add,
    sub,
    mul,
};

pub const Registers = struct {
    // can use [*]RSIZE[register_number] on these RSIZE registers
    a: RSIZE = 0,
    b: RSIZE = 0,
    c: RSIZE = 0,
    d: RSIZE = 0,

    zero: RSIZE = 0, // Keep this at zero, helpful register to have in order to reduce code size
    ofl: RSIZE = 0, // Overflow flag. Increments by one each time an overflow occurs

    // cannot use that hack here, as size is now varying
    ip: usize = 0, // Instruction pointer
};

pub const Register = enum {
    a,
    b,
    c,
    d,
    zero,
};

// Sanity checking tests
test "ensure opcodes match stored operation order" {
    const std = @import("std");
    inline for (std.meta.fields(Opcode)) |oc| {
        const operation = Operations[oc.value];
        std.testing.expect(std.mem.eql(u8, oc.name, operation.name));
    }
}

test "ensure Register enum matches stored Registers order" {
    const std = @import("std");

    inline for (std.meta.fields(Register)) |r| {
        const register = std.meta.fields(Registers)[r.value];
        // std.debug.warn("x : {}\n", .{register});
        std.testing.expect(std.mem.eql(u8, r.name, register.name));
    }
}
