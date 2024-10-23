const hal = @import("Zwrapper/hal_include.zig").stm32;
const zuart = @import("Zwrapper/uart_wrapper.zig").Zuart;
const zgpio = @import("Zwrapper/gpio_wrapper.zig").Zgpio;
const zuitl = @import("Zwrapper/util_wrapper.zig").Zutil;
const Os = @import("RTOS/os.zig");
const Mutex = Os.Mutex;
const EventGroup = Os.EventGroup;
const OsError = Os.OsError;
const Sem = Os.Semaphore;
const MsgQueue = Os.createMsgQueueType(.{ .MsgType = LedMsg, .buffer_size = 3 });
const Timer = Os.Timer;

const blink_time = 500;

const TestType = enum {
    mutex,
    semaphore,
    event_group,
    msg_q,
    timer,
};

const test_type = TestType.timer;

var led_mutex = Mutex.create_mutex("led_mutex");
var sem = Sem.create_semaphore(.{ .name = "led_semaphore", .inital_value = 2 });
var event_group = EventGroup.createEventGroup(.{ .name = "led_event_group" });
var msg_queue = MsgQueue.createQueue(.{ .name = "led_msg", .inital_val = LedMsg.off });
var timer = Timer.create(.{ .name = "led_timer", .callback = &timerCallback });
var timer2 = Timer.create(.{ .name = "led_timer2", .callback = &timerCallback2 });

const LedMsg = enum { toggle, on, off };

var timerLed: zgpio = .{ .m_port = hal.GPIOA, .m_pin = hal.GPIO_PIN_10 };

var led1: zgpio = .{ .m_port = hal.GPIOA, .m_pin = hal.GPIO_PIN_6 };
var led2: zgpio = .{ .m_port = hal.GPIOA, .m_pin = hal.GPIO_PIN_8 };
var led3: zgpio = .{ .m_port = hal.GPIOA, .m_pin = hal.GPIO_PIN_9 };
var led4: zgpio = .{ .m_port = hal.GPIOA, .m_pin = hal.GPIO_PIN_10 };

fn timerCallback() void {
    led1.TogglePin();
}

fn timerCallback2() void {
    led2.TogglePin();
}

fn idleTask() !void {
    var led = zgpio{ .m_port = hal.GPIOC, .m_pin = hal.GPIO_PIN_13 };
    while (true) {
        led.TogglePin();
        zuitl.delay(100);
    }
}

fn task1() !void {
    while (true) {
        switch (test_type) {
            .event_group => {
                _ = try event_group.awaitEvent(.{ .event_mask = 0b01, .PendOn = .any_set });
                try event_group.writeEvent(.{ .event = 0b00 });
                led1.TogglePin();
            },
            .msg_q => {
                const msg = try msg_queue.awaitMsg(.{});
                switch (msg) {
                    .on => led1.WritePin(.Set),
                    .off => led1.WritePin(.Reset),
                    .toggle => led1.TogglePin(),
                }
            },
            .mutex => {
                try mutex_blink(&led1);
            },
            .semaphore => {
                try semaphore_blink(&led1);
            },
            .timer => {
                try timer.set(.{ .autoreload = true, .timeout_ms = 250 });
                try timer2.set(.{ .autoreload = true, .timeout_ms = 500 });
                try timer.start();
                try timer2.start();
                try tcb1.suspendMe();
            },
        }
    }
}

fn task2() !void {
    while (true) {
        switch (test_type) {
            .event_group => {
                _ = try event_group.awaitEvent(.{ .event_mask = 0b10, .PendOn = .any_set });
                try event_group.writeEvent(.{ .event = 0b00 });
                led2.TogglePin();
            },
            .msg_q => {
                try msg_queue.pushMsg(LedMsg.off);
                try Os.Time.delay(blink_time);
                try msg_queue.pushMsg(LedMsg.on);
                try Os.Time.delay(blink_time);
            },
            .mutex => {
                try mutex_blink(&led2);
            },
            .semaphore => {
                try semaphore_blink(&led2);
            },
            .timer => {
                try tcb2.suspendMe();
            },
        }
    }
}

fn task3() !void {
    while (true) {
        switch (test_type) {
            .event_group => {
                try event_group.writeEvent(.{ .event = 0b01 });
                try Os.Time.delay(blink_time);
                try event_group.writeEvent(.{ .event = 0b10 });
                try Os.Time.delay(blink_time);
            },
            .msg_q => {
                try tcb3.suspendMe();
            },
            .mutex => {
                try mutex_blink(&led3);
            },
            .semaphore => {
                try semaphore_blink(&led3);
            },
            .timer => {
                try tcb3.suspendMe();
            },
        }
    }
}

fn mutex_blink(gpio: *zgpio) !void {
    try led_mutex.acquire(.{});
    const led = gpio;
    led.TogglePin();
    try Os.Time.delay(blink_time);
    try led_mutex.release();
    try Os.Time.delay(blink_time);
}

fn semaphore_blink(gpio: *zgpio) !void {
    try sem.wait(.{});
    gpio.TogglePin();
    try Os.Time.delay(blink_time);
    try sem.post(.{});
    try Os.Time.delay(1);
}

const stackSize = 500;
var stack1: [stackSize]u32 = [_]u32{0xDEADC0DE} ** stackSize;
var stack2: [stackSize]u32 = [_]u32{0xDEADC0DE} ** stackSize;
var stack3: [stackSize]u32 = [_]u32{0xDEADC0DE} ** stackSize;

var tcb1 = Os.create_task(.{
    .name = "task1",
    .priority = 1,
    .stack = &stack1,
    .subroutine = &task1,
    //    .subroutineErrHandler = &errorHandler,
});

fn errorHandler(err: anyerror) void {
    if (err == OsError.Aborted) {}
}

var tcb2 = Os.create_task(.{
    .name = "task2",
    .priority = 2,
    .stack = &stack2,
    .subroutine = &task2,
});

var tcb3 = Os.create_task(.{
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

    tcb1.init();
    tcb2.init();
    tcb3.init();

    sem.init() catch {};
    event_group.init() catch {};
    msg_queue.init() catch {};
    led_mutex.init() catch {};

    Os.init();
    Os.startOS(.{
        .idle_task_subroutine = &idleTask,
        .idle_stack_size = 25,
        .os_tick_callback = &incTick,
        .timer_config = .{
            .timer_enable = true,
            .timer_stack_size = 100,
            .timer_task_priority = 0,
        },
    });

    unreachable;
}

extern var uwTick: c_uint;
fn incTick() void {
    uwTick += 1;
}

const std = @import("std");
const builtin = @import("builtin");
pub fn panic(msg: []const u8, _: ?*std.builtin.StackTrace, _: ?usize) noreturn {
    var pcCom = zuart{ .m_uart_handle = &hal.huart2 };
    pcCom.writeBlocking("--Panic--\n", 50) catch {};
    pcCom.writeBlocking(msg, 250) catch {};
    pcCom.writeBlocking("\n", 50) catch {};

    while (true) {
        //@breakpoint();
    }
}
