const std = @import("std");

pub fn build(b: *std.Build) void {

    //stm32f103
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .thumb,
        .cpu_model = .{ .explicit = &std.Target.arm.cpu.cortex_m3 },
        .abi = .eabi,
        .os_tag = .freestanding,
    });

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const elf = b.addExecutable(.{
        .name = "gps.elf",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    elf.addAssemblyFile(.{ .path = "src/startup_stm32f103xb.s" });
    elf.setLinkerScript(.{ .path = "STM32F103C8Tx_FLASH.ld" });
    b.installArtifact(elf);
}
