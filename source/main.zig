const hal = @import("Zwrapper/hal_include.zig").stm32;
const zuart = @import("Zwrapper/uart_wrapper.zig").Zuart;
const zgpio = @import("Zwrapper/gpio_wrapper.zig").Zgpio;
const zuitl = @import("Zwrapper/util_wrapper.zig").Zutil;
const Os = @import("RTOS/os.zig");
const Mutex = Os.Mutex;
const EventGroup = Os.EventGroup;
const OsError = Os.OsError;
const EventOperation = Os.EventOperation;

const blink_time = 500;

fn idleTask() !void {
    var led = zgpio{ .m_port = hal.GPIOC, .m_pin = hal.GPIO_PIN_13 };
    while (true) {
        led.TogglePin();
        zuitl.delay(1000);
    }
}

var eventGroup = EventGroup.createEventGroup(.{ .name = "myEvent" });
const event1: usize = 0b1;
const event2: usize = 0b10;

fn task1() !void {
    try Os.delay(200);
    while (true) {
        try eventGroup.writeEvents(.{ .event = event1 });
        try Os.delay(500);
        try eventGroup.writeEvents(.{ .event = event2 });
        try Os.delay(500);
    }
}

fn task2() !void {
    var myLed: zgpio = .{ .m_port = hal.GPIOA, .m_pin = hal.GPIO_PIN_8 };
    while (true) {
        const my_event = try eventGroup.pendEvent(.{ .event_mask = event1, .PendOn = EventOperation.set_all });
        if (my_event == event1) {
            myLed.TogglePin();
            try eventGroup.writeEvents(.{ .event = 0 });
        }
    }
}

fn task3() !void {
    var myLed: zgpio = .{ .m_port = hal.GPIOA, .m_pin = hal.GPIO_PIN_9 };
    while (true) {
        const my_event = try eventGroup.pendEvent(.{ .event_mask = event2, .PendOn = EventOperation.set_all });
        if (my_event == event2) {
            myLed.TogglePin();
            try eventGroup.writeEvents(.{ .event = 0 });
        }
    }
}

var led_mutex = Mutex.create_mutex("led_mutex");

fn blink(gpio: zgpio) !void {
    try led_mutex.acquire(.{});
    const led = gpio;
    led.TogglePin();
    try Os.delay(1);
    try led_mutex.release();
    try Os.delay(500);
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
});

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

    tcb1.initalize();
    tcb2.initalize();
    tcb3.initalize();

    eventGroup.initalize();

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
