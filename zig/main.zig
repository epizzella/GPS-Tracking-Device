const hal = @import("Zwrapper/hal_include.zig").stm32;
const zuart = @import("Zwrapper/uart_wrapper.zig").ZUart;

export fn main() void {
    _ = hal.HAL_Init();
    _ = hal.SystemClock_Config();
    _ = hal.MX_GPIO_Init();
    _ = hal.MX_USART2_UART_Init();
    _ = hal.MX_USART3_UART_Init();
    _ = hal.MX_TIM3_Init();
    _ = hal.MX_TIM4_Init();

    var pcCom = zuart{ .m_uart_handle = &hal.huart2 };

    pcCom.writeBlocking("hello world!\n", 50);

    while (true) {
        hal.HAL_GPIO_TogglePin(hal.GPIOC, hal.GPIO_PIN_13);
        hal.HAL_Delay(250);
    }
}
