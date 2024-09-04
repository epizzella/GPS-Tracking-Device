const hal = @import("Zwrapper/hal_include.zig").stm32;
const zuart = @import("Zwrapper/uart_wrapper.zig").Zuart;
const zgpio = @import("Zwrapper/gpio_wrapper.zig").Zgpio;
const zuitl = @import("Zwrapper/util_wrapper.zig").Zutil;
const os = @import("Os/os_core.zig");

fn task() callconv(.C) void {
    const led = zgpio{ .m_port = hal.GPIOC, .m_pin = hal.GPIO_PIN_13 };
    while (true) {
        led.TogglePin();
        os.delay(500);
    }
}

fn task2() callconv(.C) void {
    const led = zgpio{ .m_port = hal.GPIOA, .m_pin = hal.GPIO_PIN_6 };
    while (true) {
        led.TogglePin();
        os.delay(100);
    }
}

fn task3() callconv(.C) void {
    const led = zgpio{ .m_port = hal.GPIOA, .m_pin = hal.GPIO_PIN_8 };
    while (true) {
        led.TogglePin();
        os.delay(200);
    }
}

fn task4() callconv(.C) void {
    const led = zgpio{ .m_port = hal.GPIOA, .m_pin = hal.GPIO_PIN_9 };
    while (true) {
        led.TogglePin();
        os.delay(300);
    }
}

fn task5() callconv(.C) void {
    const led = zgpio{ .m_port = hal.GPIOA, .m_pin = hal.GPIO_PIN_10 };
    while (true) {
        led.TogglePin();
        os.delay(400);
    }
}

fn task6() callconv(.C) void {
    const led = zgpio{ .m_port = hal.GPIOA, .m_pin = hal.GPIO_PIN_11 };
    while (true) {
        led.TogglePin();
        os.delay(500);
    }
}

fn task7() callconv(.C) void {
    const led = zgpio{ .m_port = hal.GPIOA, .m_pin = hal.GPIO_PIN_12 };
    while (true) {
        led.TogglePin();
        os.delay(600);
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

    const stackSize = 50;
    var stack: [stackSize]u32 = [_]u32{0xDEADC0DE} ** stackSize;
    var stack2: [stackSize]u32 = [_]u32{0xDEADC0DE} ** stackSize;
    var stack3: [stackSize]u32 = [_]u32{0xDEADC0DE} ** stackSize;
    var stack4: [stackSize]u32 = [_]u32{0xDEADC0DE} ** stackSize;
    var stack5: [stackSize]u32 = [_]u32{0xDEADC0DE} ** stackSize;
    var stack6: [stackSize]u32 = [_]u32{0xDEADC0DE} ** stackSize;
    var stack7: [stackSize]u32 = [_]u32{0xDEADC0DE} ** stackSize;

    var tcb1 = os.Task{
        .stack = &stack,
        .stack_ptr = @intFromPtr(&stack[stack.len - 16]),
        .task_handler = &task,
        .priority = 5,
        .blocked_time = 0,
        .towardHead = null,
        .towardTail = null,
    };

    var tcb2 = os.Task{
        .stack = &stack2,
        .stack_ptr = @intFromPtr(&stack2[stack2.len - 16]),
        .task_handler = &task2,
        .priority = 5,
        .blocked_time = 0,
        .towardHead = null,
        .towardTail = null,
    };

    var tcb3 = os.Task{
        .stack = &stack3,
        .stack_ptr = @intFromPtr(&stack3[stack3.len - 16]),
        .task_handler = &task3,
        .priority = 5,
        .blocked_time = 0,
        .towardHead = null,
        .towardTail = null,
    };

    var tcb4 = os.Task{
        .stack = &stack4,
        .stack_ptr = @intFromPtr(&stack4[stack4.len - 16]),
        .task_handler = &task4,
        .priority = 6,
        .blocked_time = 0,
        .towardHead = null,
        .towardTail = null,
    };

    var tcb5 = os.Task{
        .stack = &stack5,
        .stack_ptr = @intFromPtr(&stack5[stack5.len - 16]),
        .task_handler = &task5,
        .priority = 6,
        .blocked_time = 0,
        .towardHead = null,
        .towardTail = null,
    };

    var tcb6 = os.Task{
        .stack = &stack6,
        .stack_ptr = @intFromPtr(&stack6[stack6.len - 16]),
        .task_handler = &task6,
        .priority = 6,
        .blocked_time = 0,
        .towardHead = null,
        .towardTail = null,
    };

    var tcb7 = os.Task{
        .stack = &stack7,
        .stack_ptr = @intFromPtr(&stack7[stack7.len - 16]),
        .task_handler = &task7,
        .priority = 13,
        .blocked_time = 0,
        .towardHead = null,
        .towardTail = null,
    };

    os.addTaskToOs(&tcb1);
    os.addTaskToOs(&tcb2);
    os.addTaskToOs(&tcb3);
    os.addTaskToOs(&tcb4);
    os.addTaskToOs(&tcb5);
    os.addTaskToOs(&tcb6);
    os.addTaskToOs(&tcb7);

    os.startOS();
}

var pcCom = zuart{ .m_uart_handle = &hal.huart2 };

const std = @import("std");
const builtin = @import("builtin");
pub fn panic(msg: []const u8, _: ?*std.builtin.StackTrace, _: ?usize) noreturn {
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
        asm volatile ("BKPT");
    }
}
