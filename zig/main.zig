const stm32 = @cImport({
    //STM32F103xB is defined here to silence the zls error, however the program builds fine without it
    //since it is also defined in the zig.build where it is required.
    @cDefine("STM32F103xB", "");
    @cInclude("stm32f1xx_hal.h");
    @cInclude("clock.h");
    @cInclude("tim.h");
    @cInclude("usart.h");
    @cInclude("gpio.h");
});

const zuart = @import("Zwrapper/uart_wrapper.zig");

export fn main() void {
    _ = stm32.HAL_Init();
    _ = stm32.SystemClock_Config();
    _ = stm32.MX_GPIO_Init();
    _ = stm32.MX_USART2_UART_Init();
    _ = stm32.MX_USART3_UART_Init();
    _ = stm32.MX_TIM3_Init();
    _ = stm32.MX_TIM4_Init();

    while (true) {
        stm32.HAL_GPIO_TogglePin(stm32.GPIOC, stm32.GPIO_PIN_13);
        stm32.HAL_Delay(250);
    }
}
