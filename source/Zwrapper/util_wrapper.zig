const hal = @import("hal_include.zig").stm32;

pub const Zutil = struct {
    pub fn delay(ms: u32) void {
        hal.HAL_Delay(ms);
    }

    pub fn getTick() u32 {
        return hal.HAL_GetTick();
    }
};
