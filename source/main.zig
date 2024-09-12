const hal = @import("Zwrapper/hal_include.zig").stm32;
const zuart = @import("Zwrapper/uart_wrapper.zig").Zuart;
const zgpio = @import("Zwrapper/gpio_wrapper.zig").Zgpio;
const zuitl = @import("Zwrapper/util_wrapper.zig").Zutil;
const os = @import("Os/os.zig");

const blink = 500;

fn idleTask() void {
    const led = zgpio{ .m_port = hal.GPIOC, .m_pin = hal.GPIO_PIN_13 };
    while (true) {
        led.TogglePin();
        zuitl.delay(1000);
    }
}

fn task1() void {
    const led = zgpio{ .m_port = hal.GPIOA, .m_pin = hal.GPIO_PIN_6 };
    while (true) {
        led.TogglePin();
        os.delay(blink);
    }
}

fn task2() void {
    const led = zgpio{ .m_port = hal.GPIOA, .m_pin = hal.GPIO_PIN_8 };
    while (true) {
        led.TogglePin();
        os.delay(blink);
    }
}

export fn main() void {
    _ = hal.HAL_Init();
    _ = hal.SystemClock_Config();
    _ = hal.MX_GPIO_Init();
    _ = hal.MX_USART2_UART_Init();
    _ = hal.MX_USART3_UART_Init();
    _ = hal.MX_TIM3_Init();
    _ = hal.MX_TIM4_Init();

    const stackSize = 25;
    var stack1: [stackSize]u32 = [_]u32{0xDEADC0DE} ** stackSize;
    var stack2: [stackSize]u32 = [_]u32{0xDEADC0DE} ** stackSize;

    var tcb1 = os.create_task(.{
        .name = "task1",
        .priority = 2,
        .stack = &stack1,
        .subroutine = &task1,
    });

    var tcb2 = os.create_task(.{
        .name = "task2",
        .priority = 3,
        .stack = &stack2,
        .subroutine = &task2,
    });

    os.addTaskToOs(&tcb1);
    os.addTaskToOs(&tcb2);
    os.coreInit();
    os.startOS(.{
        .idle_task_subroutine = &idleTask,
        .idle_stack_size = 25,
        .sysTick_callback = &incTick,
    });
}

extern var uwTick: c_uint;
fn incTick() void {
    uwTick += 1;
}

const std = @import("std");
const builtin = @import("builtin");
pub fn panic(msg: []const u8, _: ?*std.builtin.StackTrace, _: ?usize) noreturn {
    var pcCom = zuart{ .m_uart_handle = &hal.huart2 };
    pcCom.writeBlocking("--Panic--\n", 500) catch blk: {
        break :blk;
    };
    pcCom.writeBlocking(msg, 500) catch blk: {
        break :blk;
    };
    pcCom.writeBlocking("\n", 500) catch blk: {
        break :blk;
    };

    while (true) {
        @breakpoint();
    }
}
