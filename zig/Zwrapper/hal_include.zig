//All of your c imports now belong to us
pub const stm32 = @cImport({
    //STM32F103xB is defined here to silence the zls error, however the program builds fine without it
    //since it is also defined in the zig.build where it is required.
    @cDefine("STM32F103xB", "");
    @cInclude("stm32f1xx_hal.h");
    @cInclude("clock.h");
    @cInclude("usart.h");
    @cInclude("tim.h");
    @cInclude("usart.h");
    @cInclude("gpio.h");
});

pub const HalStatus = struct {
    pub fn StatusToErr(status: stm32.HAL_StatusTypeDef) errors!void {
        switch (status) {
            1 => return errors.HAL_ERROR,
            2 => return errors.HAL_BUSY,
            3 => return errors.HAL_TIMEOUT,
            else => return,
        }
    }

    pub const errors = error{
        HAL_ERROR,
        HAL_BUSY,
        HAL_TIMEOUT,
    };
};
