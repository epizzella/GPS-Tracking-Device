const hal = @import("Zwrapper/hal_include.zig").stm32;
const zuart = @import("Zwrapper/uart_wrapper.zig").Zuart;
const zgpio = @import("Zwrapper/gpio_wrapper.zig").Zgpio;
const zuitl = @import("Zwrapper/util_wrapper.zig").Zutil;
const OS = @import("RTOS/os.zig");
const mutex = OS.Mutex;

const blink_time = 500;

fn idleTask() void {
    const led = zgpio{ .m_port = hal.GPIOC, .m_pin = hal.GPIO_PIN_13 };
    while (true) {
        led.TogglePin();
        zuitl.delay(1000);
    }
}

fn task1() void {
    while (true) {
        blink(.{ .m_port = hal.GPIOA, .m_pin = hal.GPIO_PIN_6 });
    }
}

fn task2() void {
    while (true) {
        blink(.{ .m_port = hal.GPIOA, .m_pin = hal.GPIO_PIN_8 });
    }
}

fn task3() void {
    while (true) {
        blink(.{ .m_port = hal.GPIOA, .m_pin = hal.GPIO_PIN_9 });
    }
}

var led_mutex = mutex.Mutex.create_mutex("led_mutex");
fn blink(gpio: zgpio) void {
    led_mutex.acquire();
    const led = gpio;
    led.TogglePin();
    OS.delay(1);
    led_mutex.release();
    OS.delay(500);
}

const stackSize = 500;
var stack1: [stackSize]u32 = [_]u32{0xDEADC0DE} ** stackSize;
var stack2: [stackSize]u32 = [_]u32{0xDEADC0DE} ** stackSize;
var stack3: [stackSize]u32 = [_]u32{0xDEADC0DE} ** stackSize;

var tcb1 = OS.create_task(.{
    .name = "task1",
    .priority = 1,
    .stack = &stack1,
    .subroutine = &task1,
});

var tcb2 = OS.create_task(.{
    .name = "task2",
    .priority = 2,
    .stack = &stack2,
    .subroutine = &task2,
});

var tcb3 = OS.create_task(.{
    .name = "task3",
    .priority = 3,
    .stack = &stack3,
    .subroutine = &task3,
});

export fn main() void {
    _ = hal.HAL_Init();
    _ = hal.SystemClock_Config();
    _ = hal.MX_GPIO_Init();
    _ = hal.MX_USART2_UART_Init();
    _ = hal.MX_USART3_UART_Init();
    _ = hal.MX_TIM3_Init();
    _ = hal.MX_TIM4_Init();

    OS.addTaskToOs(&tcb1);
    OS.addTaskToOs(&tcb2);
    OS.addTaskToOs(&tcb3);
    OS.coreInit();
    OS.startOS(.{
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
