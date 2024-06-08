const os = @import("Os/zOs.zig");

extern var uwTick: c_uint;
pub export fn SysTick_Handler() void {
    uwTick += 1; //adding 1 counts up at 1ms
    os.tick();
}

pub export fn PendSV_Handler() void {
    os.context_swtich();
}
