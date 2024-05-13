const hal = @import("Zwrapper/hal_include.zig").stm32;
const zuart = @import("Zwrapper/uart_wrapper.zig").Zuart;
const zgpio = @import("Zwrapper/gpio_wrapper.zig").Zgpio;
const zuitl = @import("Zwrapper/util_wrapper.zig").Zutil;

export fn main() void {
    _ = hal.HAL_Init();
    _ = hal.SystemClock_Config();
    _ = hal.MX_GPIO_Init();
    _ = hal.MX_USART2_UART_Init();
    _ = hal.MX_USART3_UART_Init();
    _ = hal.MX_TIM3_Init();
    _ = hal.MX_TIM4_Init();

    var pcCom = zuart{ .m_uart_handle = &hal.huart2 };
    const led = zgpio{ .m_port = hal.GPIOC, .m_pin = hal.GPIO_PIN_13 };

    pcCom.writeBlocking("hello world!\n", 50) catch blk: {
        break :blk;
    };

    while (true) {
        led.TogglePin();
        zuitl.delay(500);
    }
}
