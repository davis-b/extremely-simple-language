// Tested with zig version 0.7.1
const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const programs = .{
        .{ "vm", "src/interpreter.zig" },
        .{ "compiler", "src/compiler.zig" },
    };
    inline for (programs) |p| {
        const exe = b.addExecutable(p[0], p[1]);
        exe.setTarget(target);
        exe.setBuildMode(mode);
        exe.install();
    }

    // const run_cmd = exe.run();
    // run_cmd.step.dependOn(b.getInstallStep());

    // const run_step = b.step("run", "Run the app");
    // run_step.dependOn(&run_cmd.step);

    const test_step = b.step("test", "Run library tests");
    const tests = [_][]const u8{
        "src/interpreter.zig",
    };
    for (tests) |path| {
        var test_ = b.addTest(path);
        test_.setTarget(target);
        test_.setBuildMode(mode);
        // test_.linkLibC();
        test_step.dependOn(&test_.step);
    }
}
