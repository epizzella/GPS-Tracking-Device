const hal = @import("hal_include.zig").stm32;
const halStatus = @import("hal_include.zig").HalStatus;

pub const ZpinState = enum {
    Reset,
    Set,
};

pub const Zgpio = struct {
    m_port: *hal.GPIO_TypeDef,
    m_pin: u16,

    pub fn ReadPin(self: *Zgpio) ZpinState {
        return hal.HAL_GPIO_ReadPin(self.m_port, self.m_pin);
    }

    pub fn WritePin(self: *Zgpio, pinState: ZpinState) void {
        hal.HAL_GPIO_WritePin(self.m_port, self.m_pin, @intFromEnum(pinState));
    }

    pub fn TogglePin(self: *Zgpio) void {
        hal.HAL_GPIO_TogglePin(self.m_port, self.m_pin);
    }

    pub fn LockPin(self: *Zgpio) halStatus.errors!void {
        const status = hal.HAL_GPIO_LockPin(self.m_port, self.m_pin);
        if (status > 0) {
            return halStatus.StatusToErr(status);
        }
    }
};
