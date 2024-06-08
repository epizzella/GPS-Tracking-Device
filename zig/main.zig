const hal = @import("Zwrapper/hal_include.zig").stm32;
const zuart = @import("Zwrapper/uart_wrapper.zig").Zuart;
const zgpio = @import("Zwrapper/gpio_wrapper.zig").Zgpio;
const zuitl = @import("Zwrapper/util_wrapper.zig").Zutil;
const zOs = @import("Os/zOs.zig");
const os_user = @import("os_user.zig");
const std = @import("std");

fn task() callconv(.C) void {
    const led = zgpio{ .m_port = hal.GPIOC, .m_pin = hal.GPIO_PIN_13 };
    while (true) {
        led.TogglePin();
        zOs.delay(250);
    }
}

fn task2() callconv(.C) void {
    const led = zgpio{ .m_port = hal.GPIOA, .m_pin = hal.GPIO_PIN_6 };
    while (true) {
        led.TogglePin();
        zOs.delay(250);
    }
}

export fn main() void {
    std.mem.doNotOptimizeAway(os_user.SysTick_Handler);
    std.mem.doNotOptimizeAway(os_user.PendSV_Handler);
    _ = hal.HAL_Init();
    _ = hal.SystemClock_Config();
    _ = hal.MX_GPIO_Init();
    _ = hal.MX_USART2_UART_Init();
    _ = hal.MX_USART3_UART_Init();
    _ = hal.MX_TIM3_Init();
    _ = hal.MX_TIM4_Init();

    var pcCom = zuart{ .m_uart_handle = &hal.huart2 };

    pcCom.writeBlocking("hello world!\n", 50) catch blk: {
        break :blk;
    };

    //pcCom.write("hello world interrupted!\n") catch blk: {
    //    break :blk;
    //};

    var stack: [100]u32 = undefined;
    var stack2: [100]u32 = undefined;
    zOs.Task.create_task(&stack, &task, 0);
    zOs.Task.create_task(&stack2, &task2, 1);
    zOs.start();
}
