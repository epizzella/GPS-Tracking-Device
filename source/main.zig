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

const blink_time = 500;

const TestType = enum {
    mutex,
    semaphore,
    event_group,
    msg_q,
};

const test_type = TestType.event_group;

var led_mutex = Mutex.create_mutex("led_mutex");
var sem = Sem.create_semaphore(.{ .name = "led_semaphore", .inital_value = 2 });
var event_group = EventGroup.createEventGroup(.{ .name = "led_event_group" });
var msg_queue = MsgQueue.createQueue(.{ .name = "led_msg", .inital_val = LedMsg.off });

const LedMsg = enum { toggle, on, off };

fn idleTask() !void {
    var led = zgpio{ .m_port = hal.GPIOC, .m_pin = hal.GPIO_PIN_13 };
    while (true) {
        led.TogglePin();
        zuitl.delay(100);
    }
}

fn task1() !void {
    var myLed: zgpio = .{ .m_port = hal.GPIOA, .m_pin = hal.GPIO_PIN_6 };
    while (true) {
        switch (test_type) {
            .event_group => {
                _ = try event_group.awaitEvent(.{ .event_mask = 0b01, .PendOn = .any_set });
                try event_group.writeEvent(.{ .event = 0b00 });
                myLed.TogglePin();
            },
            .msg_q => {
                const msg = try msg_queue.awaitMsg(.{});
                switch (msg) {
                    .on => myLed.WritePin(.Set),
                    .off => myLed.WritePin(.Reset),
                    .toggle => myLed.TogglePin(),
                }
            },
            .mutex => {
                try mutex_blink(&myLed);
            },
            .semaphore => {
                try semaphore_blink(&myLed);
            },
        }
    }
}

fn task2() !void {
    var myLed: zgpio = .{ .m_port = hal.GPIOA, .m_pin = hal.GPIO_PIN_8 };
    while (true) {
        switch (test_type) {
            .event_group => {
                _ = try event_group.awaitEvent(.{ .event_mask = 0b10, .PendOn = .any_set });
                try event_group.writeEvent(.{ .event = 0b00 });
                myLed.TogglePin();
            },
            .msg_q => {
                try msg_queue.pushMsg(LedMsg.off);
                try Os.Time.delay(blink_time);
                try msg_queue.pushMsg(LedMsg.on);
                try Os.Time.delay(blink_time);
            },
            .mutex => {
                try mutex_blink(&myLed);
            },
            .semaphore => {
                try semaphore_blink(&myLed);
            },
        }
    }
}

fn task3() !void {
    var myLed: zgpio = .{ .m_port = hal.GPIOA, .m_pin = hal.GPIO_PIN_9 };
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
                try mutex_blink(&myLed);
            },
            .semaphore => {
                try semaphore_blink(&myLed);
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
    try sem.acquire(.{});
    gpio.TogglePin();
    try Os.Time.delay(blink_time);
    try sem.release();
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

    sem.init();
    event_group.init();
    msg_queue.init();
    led_mutex.init();

    Os.init();
    Os.startOS(.{
        .idle_task_subroutine = &idleTask,
        .idle_stack_size = 25,
        .sysTick_callback = &incTick,
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
