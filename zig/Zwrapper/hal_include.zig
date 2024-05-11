//All of your c imports now belong to us
pub const stm32 = @cImport({
    //STM32F103xB is defined here to silence the zls error, however the program builds fine without it
    //since it is also defined in the zig.build where it is required.
    @cDefine("STM32F103xB", "");
    @cInclude("stm32f1xx_hal.h");
    @cInclude("stm32f1xx_hal_uart.h");
    @cInclude("usart.h");
    @cInclude("clock.h");
    @cInclude("tim.h");
    @cInclude("usart.h");
    @cInclude("gpio.h");
});
