const ARMv7M = @import("arm-cortex-m/common/arch.zig");
const TestArch = @import("test/test_arch.zig");
const builtin = @import("builtin");
const std = @import("std");
const cpu = std.Target.arm.cpu;

pub fn getArch(comptime cpu_model: *const std.Target.Cpu.Model) Arch {
    if (builtin.is_test == true) {
        return Arch{ .test_arch = TestArch };
    } else if (cpu_model == &cpu.cortex_m0 or cpu_model == &cpu.cortex_m0plus) {
        @compileError("Unsupported architecture selected.");
    } else if (cpu_model == &cpu.cortex_m3 or cpu_model == &cpu.cortex_m4 or cpu_model == &cpu.cortex_m7) {
        return Arch{ .armv7_m = ARMv7M{} };
    } else if (cpu_model == &cpu.cortex_m23 or cpu_model == &cpu.cortex_m33 or cpu_model == &cpu.cortex_m55 and cpu_model == &cpu.cortex_m85) {
        @compileError("Unsupported architecture selected.");
    } else {
        @compileError("Unsupported architecture selected.");
    }
}

const Arch = union(enum) {
    armv7_m: ARMv7M,
    test_arch: TestArch,

    const Self = @This();

    pub fn coreInit(self: *Self) void {
        switch (self.*) {
            inline else => |*case| return case.coreInit(),
        }
    }

    pub fn interruptActive(self: *Self) bool {
        switch (self.*) {
            inline else => |*case| return case.interruptActive(),
        }
    }

    ///Enable Interrupts
    pub inline fn criticalEnd(self: *Self) void {
        switch (self.*) {
            inline else => |*case| return case.criticalEnd(),
        }
    }

    ///Disable Interrupts
    pub inline fn criticalStart(self: *Self) void {
        switch (self.*) {
            inline else => |*case| return case.criticalStart(),
        }
    }

    pub inline fn runScheduler(self: *Self) void {
        switch (self.*) {
            inline else => |*case| return case.runScheduler(),
        }
    }

    pub inline fn runContextSwitch(self: *Self) void {
        switch (self.*) {
            inline else => |*case| return case.runContextSwitch(),
        }
    }

    pub inline fn isDebugAttached(self: *Self) bool {
        switch (self.*) {
            inline else => |*case| return case.isDebugAttached(),
        }
    }
};
