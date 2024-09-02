const hal = @import("Zwrapper/hal_include.zig").stm32;
const zuart = @import("Zwrapper/uart_wrapper.zig").Zuart;
const zgpio = @import("Zwrapper/gpio_wrapper.zig").Zgpio;
const zuitl = @import("Zwrapper/util_wrapper.zig").Zutil;
const os = @import("Os/os_core.zig");
const os_user = @import("os_user.zig");
const std = @import("std");

fn task() callconv(.C) void {
    const led = zgpio{ .m_port = hal.GPIOC, .m_pin = hal.GPIO_PIN_13 };
    while (true) {
        led.TogglePin();
        os._delay(250);
    }
}

fn task2() callconv(.C) void {
    const led = zgpio{ .m_port = hal.GPIOA, .m_pin = hal.GPIO_PIN_6 };
    while (true) {
        led.TogglePin();
        os._delay(100);
    }
}

fn _idle_task_handler() callconv(.C) void {
    while (true) {
        //idle
        //add a call back for the user to set
    }
}

export fn main() void {
    std.mem.doNotOptimizeAway(os_user.SysTick_Handler);
    std.mem.doNotOptimizeAway(os_user.PendSV_Handler);
    std.mem.doNotOptimizeAway(_idle_task_handler);
    _ = hal.HAL_Init();
    _ = hal.SystemClock_Config();
    _ = hal.MX_GPIO_Init();
    _ = hal.MX_USART2_UART_Init();
    _ = hal.MX_USART3_UART_Init();
    _ = hal.MX_TIM3_Init();
    _ = hal.MX_TIM4_Init();

    //var pcCom = zuart{ .m_uart_handle = &hal.huart2 };

    // pcCom.writeBlocking(test_var, 50) catch blk: {
    //     break :blk;
    // };

    // pcCom.write("hello world interrupted!\n") catch blk: {
    //     break :blk;
    // };

    //   var stack: [100]u32 = undefined;
    //   var stack2: [100]u32 = undefined;

    //os.create_task(&stack, &task, 0);
    //os.create_task(&stack2, &task2, 1);
    //os.start();

    const stackSize = 100;
    var stack: [stackSize]u32 = [_]u32{0xDEADC0DE} ** stackSize;
    var stack2: [stackSize]u32 = [_]u32{0xDEADC0DE} ** stackSize;
    var _idle_stack: [stackSize]u32 = [_]u32{0xDEADC0DE} ** stackSize;

    for (0..stackSize, &stack, &stack2, &_idle_stack) |i, *s, *s2, *si| {
        s.* = i;
        s2.* = i;
        si.* = i;
    }

    var tcb1 = os.os_priorityQ.TaskCtrlBlk{
        .stack = &stack,
        .stack_ptr = @intFromPtr(&stack[stack.len - 16]),
        .task_handler = &task,
        .priority = 5,
        .blocked_time = 0,
        .towardHead = null,
        .towardTail = null,
    };

    var tcb2 = os.os_priorityQ.TaskCtrlBlk{
        .stack = &stack2,
        .stack_ptr = @intFromPtr(&stack2[stack2.len - 16]),
        .task_handler = &task2,
        .priority = 6,
        .blocked_time = 0,
        .towardHead = null,
        .towardTail = null,
    };

    var idleTask = os.os_priorityQ.TaskCtrlBlk{
        .stack = &_idle_stack,
        .stack_ptr = @intFromPtr(&_idle_stack[_idle_stack.len - 16]),
        .task_handler = &_idle_task_handler,
        .priority = 31,
        .blocked_time = 0,
        .towardHead = null,
        .towardTail = null,
    };

    os._addTaskToOs(&idleTask);
    os._addTaskToOs(&tcb1);
    os._addTaskToOs(&tcb2);
    os._startOS();
}

const builtin = @import("builtin");
pub fn panic(msg: []const u8, _: ?*std.builtin.StackTrace, _: ?usize) noreturn {
    var pcCom = zuart{ .m_uart_handle = &hal.huart2 };
    pcCom.writeBlocking("--Panic--\n", 100) catch blk: {
        break :blk;
    };
    pcCom.writeBlocking(msg, 100) catch blk: {
        break :blk;
    };
    pcCom.writeBlocking("\n", 100) catch blk: {
        break :blk;
    };

    while (true) {
        @breakpoint();
    }
}
