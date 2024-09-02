const os = @import("Os/os_core.zig");

extern var uwTick: c_uint;
pub export fn SysTick_Handler() void {
    uwTick += 1; //adding 1 counts up at 1ms
    os._tick();
}

pub export fn PendSV_Handler() void {
    os._context_swtich();
}

pub export fn SVC_Handler() void {
    os.disableInterrupts();
    os._schedule();
    os.enableInterrupts();
}
