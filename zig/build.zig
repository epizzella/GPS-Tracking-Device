const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) void {
    const prj_name = "gps";

    comptime {
        const required_zig = "0.12.0";
        const current_zig = builtin.zig_version;
        const min_zig = std.SemanticVersion.parse(required_zig) catch unreachable;
        if (current_zig.order(min_zig) == .lt) {
            const error_message =
                \\Attempting to compile with an older version of zig. This project requires development build {}
            ;
            @compileError(std.fmt.comptimePrint(error_message, .{min_zig}));
        }
    }

    //stm32f103
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .thumb,
        .cpu_model = .{ .explicit = &std.Target.arm.cpu.cortex_m3 },
        .abi = .eabi,
        .os_tag = .freestanding,
    });

    const output_dir = "bin/";
    b.exe_dir = output_dir;

    //Releasesmall generates an elf thats missing the entire symbol table for some reason
    //Debug fails to build because it won't fit into flash
    //Releasesafe and Releasefast both generate elf files that have symbol tables and fit into flash
    const optimize = std.builtin.OptimizeMode.ReleaseSafe;

    const elf = b.addExecutable(.{
        .name = prj_name ++ ".elf",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    //#defines for STM32 HAL
    elf.defineCMacro("USE_HAL_DRIVER", "");
    elf.defineCMacro("STM32F103xB", "");

    elf.addAssemblyFile(.{ .path = "startup_stm32f103xb.S" });
    elf.setLinkerScript(.{ .path = "STM32F103C8Tx_FLASH.ld" });
    //elf.setVerboseLink(true);
    //b.verbose_link = true;

    const c_flags = [_][]const u8{
        "-g3", //max debug symbols
        //"-O1", //minor optimizations
        "-Wall", //This enables all the warnings about constructions that some users consider questionable, and that are easy to avoid, even in conjunction with macros.
        "-Wextra", //This enables some extra warning flags that are not enabled by -Wall.
        "-mthumb", //Requests that the compiler targets the thumb instruction set.
        "-mlittle-endian", //arm is little endian
        "-specs=nosys.specs", //don't link to libc
        "-mcpu=cortex-m3", //Enables code generation for cortex m3.  To view a list of all the supported processors, use: -mcpu=list
        "-mfloat-abi=soft", //Software floating point
        "-ffreestanding", //In freestanding mode, the only available standard header files are: <float.h>, <iso646.h>, <limits.h>, <stdarg.h>, <stdbool.h>, <stddef.h>, and <stdint.h>
        //"-Wl,--verbose,-Map=bin/gps.map", //not giving me a map file for some reason
        "-ffunction-sections",
        "-fdata-sections",
        "-nostdlib",
        "-nostdinc",
    };

    const stm32f1_hal_src = [_][]const u8{
        "Core/Src/gpio.c",
        "Core/Src/stm32f1xx_hal_msp.c",
        "Core/Src/stm32f1xx_it.c",
        "Core/Src/system_stm32f1xx.c",
        "Core/Src/tim.c",
        "Core/Src/usart.c",
        "Core/Src/clock.c",
        "Core/Src/error_handler.c",
        "Drivers/STM32F1xx_HAL_Driver/Src/stm32f1xx_hal.c",
        "Drivers/STM32F1xx_HAL_Driver/Src/stm32f1xx_hal_cortex.c",
        "Drivers/STM32F1xx_HAL_Driver/Src/stm32f1xx_hal_dma.c",
        "Drivers/STM32F1xx_HAL_Driver/Src/stm32f1xx_hal_exti.c",
        "Drivers/STM32F1xx_HAL_Driver/Src/stm32f1xx_hal_flash.c",
        "Drivers/STM32F1xx_HAL_Driver/Src/stm32f1xx_hal_flash_ex.c",
        "Drivers/STM32F1xx_HAL_Driver/Src/stm32f1xx_hal_gpio.c",
        "Drivers/STM32F1xx_HAL_Driver/Src/stm32f1xx_hal_gpio_ex.c",
        "Drivers/STM32F1xx_HAL_Driver/Src/stm32f1xx_hal_pwr.c",
        "Drivers/STM32F1xx_HAL_Driver/Src/stm32f1xx_hal_rcc.c",
        "Drivers/STM32F1xx_HAL_Driver/Src/stm32f1xx_hal_rcc_ex.c",
        "Drivers/STM32F1xx_HAL_Driver/Src/stm32f1xx_hal_tim.c",
        "Drivers/STM32F1xx_HAL_Driver/Src/stm32f1xx_hal_tim_ex.c",
        "Drivers/STM32F1xx_HAL_Driver/Src/stm32f1xx_hal_uart.c",
    };

    const stm32f1_hal_inc = [_][]const u8{
        "Core/Inc/",
        "Drivers/CMSIS/Include/",
        "Drivers/CMSIS/Device/",
        "Drivers/STM32F1xx_HAL_Driver/Inc/",
        "Drivers/STM32F1xx_HAL_Driver/Inc/Legacy/",
    };

    //Add c source files
    elf.addCSourceFiles(.{
        .files = &stm32f1_hal_src,
        .flags = &c_flags,
    });

    //Add c inc paths
    for (stm32f1_hal_inc) |header| {
        elf.addIncludePath(.{ .path = header });
    }

    //Entry point to our program.
    //Without this we get a linker warning stating that _start is missing
    elf.entry = .{ .symbol_name = "Reset_Handler" };

    //build the elf file
    b.installArtifact(elf);

    //Additional Steps:
    //Clean workspace
    const clean_step = b.step("clean", "Cleans the workspace");
    clean_step.dependOn(&b.addRemoveDirTree(b.pathFromRoot(output_dir)).step);
    clean_step.dependOn(&b.addRemoveDirTree(b.pathFromRoot("zig-cache")).step);

    //Flash the mcu
    const openocd_flash_cmd = b.addSystemCommand(&.{
        "openocd", //openocd must be in path
        "-f", "interface/stlink.cfg", //config for stlink.  stlink must be isntalled.
        "-f", "target/stm32f1x.cfg", //config for target mcu
        "-c", "program " ++ output_dir ++ prj_name ++ ".elf " ++ "verify reset exit", //program the elf file to board
    });

    const flash_step = b.step("flash", "Runs Openocd to flash the mcu.");
    flash_step.dependOn(&openocd_flash_cmd.step);
}
