const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) void {
    const prj_name = "gps";

    comptime {
        const required_zig = "0.13.0";
        const current_zig = builtin.zig_version;
        const min_zig = std.SemanticVersion.parse(required_zig) catch unreachable;
        if (current_zig.order(min_zig) == .lt) {
            const error_message =
                \\Attempting to compile with an older version of zig. This project requires build {}
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

    const output_dir = "Bin/";
    b.exe_dir = output_dir;

    const optimize = std.builtin.OptimizeMode.Debug;

    const elf = b.addExecutable(.{
        .name = prj_name ++ ".elf",
        .root_source_file = b.path("main.zig"),
        .target = target,
        .optimize = optimize,
        .single_threaded = true,
        .link_libc = false,
        .linkage = .static,
    });

    //    elf.entry = .disabled;

    //#defines for STM32 HAL
    elf.defineCMacro("USE_HAL_DRIVER", "");
    elf.defineCMacro("STM32F103xB", "");

    elf.addAssemblyFile(.{ .src_path = .{ .owner = b, .sub_path = "startup_stm32f103xb.S" } });
    //elf.addAssemblyFile(.{ .src_path = .{ .owner = b, .sub_path = "RTOS/source/arch/arm-cortex-m/armv7-m/arch.S" } });
    elf.setLinkerScript(.{ .src_path = .{ .owner = b, .sub_path = "STM32F103C8Tx_FLASH.ld" } });
    //elf.setVerboseLink(true);
    //b.verbose_link = true;

    const c_flags = [_][]const u8{
        "-g3", //max debug symbols
        "-Wall", //This enables all the warnings about constructions that some users consider questionable, and that are easy to avoid, even in conjunction with macros.
        "-Wextra", //This enables some extra warning flags that are not enabled by -Wall.
        "-mthumb", //Requests that the compiler targets the thumb instruction set.
        "-mlittle-endian", //arm is little endian
        "-specs=nosys.nano", //setting -specs seems to be ignored.  Using elf.linkSystemLibrary("c_nano") below is what does the actual linking to nano.
        "-mcpu=cortex-m3", //Enables code generation for cortex m3.  To view a list of all the supported processors, use: -mcpu=list
        "-mfloat-abi=soft", //Software floating point
        "-ffreestanding", //In freestanding mode, the only available standard header files are: <float.h>, <iso646.h>, <limits.h>, <stdarg.h>, <stdbool.h>, <stddef.h>, and <stdint.h>
        //"-Wl,--verbose,-Map=bin/gps.map", //not giving me a map file for some reason
        //"-ffunction-sections",
        //"-fdata-sections",
        "-nostdlib",
        "-nostdinc",
        //"-gdwarf-2",
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
        "Hal/STM32F1xx_HAL_Driver/Src/stm32f1xx_hal.c",
        "Hal/STM32F1xx_HAL_Driver/Src/stm32f1xx_hal_cortex.c",
        "Hal/STM32F1xx_HAL_Driver/Src/stm32f1xx_hal_dma.c",
        "Hal/STM32F1xx_HAL_Driver/Src/stm32f1xx_hal_exti.c",
        "Hal/STM32F1xx_HAL_Driver/Src/stm32f1xx_hal_flash.c",
        "Hal/STM32F1xx_HAL_Driver/Src/stm32f1xx_hal_flash_ex.c",
        "Hal/STM32F1xx_HAL_Driver/Src/stm32f1xx_hal_gpio.c",
        "Hal/STM32F1xx_HAL_Driver/Src/stm32f1xx_hal_gpio_ex.c",
        "Hal/STM32F1xx_HAL_Driver/Src/stm32f1xx_hal_pwr.c",
        "Hal/STM32F1xx_HAL_Driver/Src/stm32f1xx_hal_rcc.c",
        "Hal/STM32F1xx_HAL_Driver/Src/stm32f1xx_hal_rcc_ex.c",
        "Hal/STM32F1xx_HAL_Driver/Src/stm32f1xx_hal_tim.c",
        "Hal/STM32F1xx_HAL_Driver/Src/stm32f1xx_hal_tim_ex.c",
        "Hal/STM32F1xx_HAL_Driver/Src/stm32f1xx_hal_uart.c",
    };

    const stm32f1_hal_inc = [_][]const u8{
        "Core/Inc/",
        "Hal/CMSIS/Include/",
        "Hal/CMSIS/Device/",
        "Hal/STM32F1xx_HAL_Driver/Inc/",
        "Hal/STM32F1xx_HAL_Driver/Inc/Legacy/",
    };

    const arm_gcc_path = "/home/fixer/arm-gcc";
    const arm_gcc_version = "13.3.1";
    // Manually including libraries bundled with arm-none-eabi-gcc
    elf.addLibraryPath(.{ .src_path = .{ .owner = b, .sub_path = b.fmt("{s}/arm-none-eabi/lib/thumb/v7/nofp", .{arm_gcc_path}) } });
    elf.addLibraryPath(.{ .src_path = .{ .owner = b, .sub_path = b.fmt("{s}/lib/gcc/arm-none-eabi/{s}/thumb/v7/nofp", .{ arm_gcc_path, arm_gcc_version }) } });
    elf.addSystemIncludePath(.{ .src_path = .{ .owner = b, .sub_path = b.fmt("{s}/arm-none-eabi/include", .{arm_gcc_path}) } });

    elf.linkSystemLibrary("c_nano");
    // elf.linkSystemLibrary("m");

    // Manually include C runtime objects bundled with arm-none-eabi-gcc
    elf.addObjectFile(.{ .src_path = .{ .owner = b, .sub_path = b.fmt("{s}/arm-none-eabi/lib/thumb/v7/nofp/crt0.o", .{arm_gcc_path}) } });
    elf.addObjectFile(.{ .src_path = .{ .owner = b, .sub_path = b.fmt("{s}/lib/gcc/arm-none-eabi/{s}/thumb/v7/nofp/crti.o", .{ arm_gcc_path, arm_gcc_version }) } });
    elf.addObjectFile(.{ .src_path = .{ .owner = b, .sub_path = b.fmt("{s}/lib/gcc/arm-none-eabi/{s}/thumb/v7/nofp/crtbegin.o", .{ arm_gcc_path, arm_gcc_version }) } });
    elf.addObjectFile(.{ .src_path = .{ .owner = b, .sub_path = b.fmt("{s}/lib/gcc/arm-none-eabi/{s}/thumb/v7/nofp/crtend.o", .{ arm_gcc_path, arm_gcc_version }) } });
    elf.addObjectFile(.{ .src_path = .{ .owner = b, .sub_path = b.fmt("{s}/lib/gcc/arm-none-eabi/{s}/thumb/v7/nofp/crtn.o", .{ arm_gcc_path, arm_gcc_version }) } });

    elf.want_lto = true; //silence ld.lld tripples warning... doesn't work
    elf.link_gc_sections = true; //equivalent to -Wl,--gc-sections

    //Add c source files
    elf.addCSourceFiles(.{
        .files = &stm32f1_hal_src,
        .flags = &c_flags,
    });

    //Add c inc paths
    for (stm32f1_hal_inc) |header| {
        elf.addIncludePath(.{ .src_path = .{ .owner = b, .sub_path = header } });
    }

    //Without setting the entry point a linker warning stating that _start or _exit is missing.
    //Since this is a freestanding binaray setting the entry point has no effect on functoinality.
    elf.entry = .{ .symbol_name = "Reset_Handler" };

    //build the elf file
    b.installArtifact(elf);

    const objcpy_bin = elf.addObjCopy(.{ .format = .bin });
    const bin_generate = b.addInstallBinFile(objcpy_bin.getOutput(), prj_name ++ ".bin");

    objcpy_bin.step.dependOn(&elf.step);
    bin_generate.step.dependOn(&objcpy_bin.step);
    b.default_step.dependOn(&bin_generate.step);

    const objcpy_hex = elf.addObjCopy(.{ .format = .hex });
    const hex_generate = b.addInstallBinFile(objcpy_hex.getOutput(), prj_name ++ ".hex");

    objcpy_hex.step.dependOn(&elf.step);
    bin_generate.step.dependOn(&objcpy_hex.step);
    b.default_step.dependOn(&hex_generate.step);

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
