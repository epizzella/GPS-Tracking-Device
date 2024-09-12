const OS_TASK = @import("../../../os_task.zig");
const OS_CORE = @import("../../../os_core.zig");

const task_ctrl_tbl = &OS_TASK.task_control_table;
const os_config = &OS_CORE._getOsConfig;
const os_started = &OS_CORE._isOsStarted;

//Core Registers
const ARM_SHPR3: *volatile u32 = @ptrFromInt(0xE000ED20);
const ARM_ICSR: *volatile u32 = @ptrFromInt(0xE000ED04);
const ARM_DHCSR: *volatile u32 = @ptrFromInt(0xE000EDF0);

//Bit Masks
const ISR_LOWEST_PRIO_MSK: u32 = 0xFF;
const PENDSV_SHPR3_MSK: u32 = ISR_LOWEST_PRIO_MSK << 16;
const SYSTICK_SHPR3_MSK: u32 = ~(ISR_LOWEST_PRIO_MSK << 24);
const C_DEBUGEN_MSK: u32 = 0x00000001;

export fn SysTick_Handler() void {
    if (os_config().sysTick_callback) |callback| {
        callback();
    }

    if (os_started()) {
        task_ctrl_tbl.updateTasksDelay();
        task_ctrl_tbl.cycleActive();
        schedule();
    }
}

export fn SVC_Handler() void {
    criticalStart();
    schedule();
    criticalEnd();
}

fn schedule() void {
    task_ctrl_tbl.readyNextTask();
    if (task_ctrl_tbl.validSwitch()) {
        runContextSwitch();
    }
}

pub fn coreInit() void {
    ARM_SHPR3.* |= ISR_LOWEST_PRIO_MSK; //Set the pendsv to the lowest priority to avoid context switch during ISR
    ARM_SHPR3.* &= SYSTICK_SHPR3_MSK; //Set sysTick to the highest priority.
}

///Enable Interrupts
pub inline fn criticalEnd() void {
    asm volatile ("CPSIE    I");
}

//Disable Interrupts
pub inline fn criticalStart() void {
    asm volatile ("CPSID    I");
}

pub inline fn runScheduler() void {
    asm volatile ("SVC      #0");
}

pub inline fn runContextSwitch() void {
    ARM_ICSR.* |= 1 << 28; //run context switch
}

pub inline fn isDebugAttached() bool {
    return (ARM_DHCSR.* & C_DEBUGEN_MSK) > 0;
}

pub inline fn getReadyTaskIndex(ready_mask: u32) u32 {
    var index: u32 = 0xFFFFFFFF;
    asm volatile ("clz    %[ready], %[mask]"
        : [ready] "=l" (index), //return
        : [mask] "l" (ready_mask), //param
    );

    return index;
}
