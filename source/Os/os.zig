const OS_TASK = @import("os_task.zig");
const OS_TYPES = @import("os_objects.zig");
const OS_CORE = @import("os_core.zig");
const ARCH = @import("arch/arm-cortex-m/common/arch.zig");

pub const Task = OS_TASK.Task;
pub const OsConfig = OS_CORE.OsConfig;
pub const coreInit = ARCH.coreInit;

const DEFAULT_IDLE_TASK_SIZE = 17;

const task_ctrl_tbl = &OS_TASK.task_control_table;

///Returns a new task.
pub fn create_task(config: OS_TASK.TaskConfig) OS_TYPES.TaskQueue.OsObject {
    return OS_TYPES.TaskQueue.OsObject{
        .name = config.name,
        ._data = Task._create_task(config),
    };
}

///Adds a task to the operating system.
pub fn addTaskToOs(task: *OS_TASK.TaskQueue.OsObject) void {
    task_ctrl_tbl.addActive(task);
}

export var g_stack_offset: u32 = 0x08;
///The operating system will begin multitasking.  This function never returns.
pub fn startOS(comptime config: OsConfig) void {
    if (OS_CORE._isOsStarted() == false) {
        comptime {
            if (config.idle_stack_size < DEFAULT_IDLE_TASK_SIZE) {
                @compileError("Idle stack size cannont be less than the default stack size: " ++ DEFAULT_IDLE_TASK_SIZE);
            }
        }

        OS_CORE._setOsConfig(config);

        var idle_stack: [config.idle_stack_size]u32 = [_]u32{0xDEADC0DE} ** config.idle_stack_size;

        var idle_task = create_task(.{
            .name = "idle task",
            .priority = 0, //Idle task priority is ignored
            .stack = &idle_stack,
            .subroutine = config.idle_task_subroutine,
        });

        task_ctrl_tbl.addIdleTask(&idle_task);

        //Find offset to stack ptr as zig does not guarantee struct field order
        g_stack_offset = @abs(@intFromPtr(&idle_task._data.stack_ptr) -% @intFromPtr(&idle_task));

        OS_CORE._setOsStarted();
        ARCH.runScheduler(); //begin os

        //if debugger is attache(d hit this breakpoint if we somehow return from os
        if (ARCH.isDebugAttached()) {
            asm volatile ("BKPT");
        }

        unreachable;
    }
}

///Put the active task to sleep.  It will become ready to run again in `time_ms `milliseconds
pub fn delay(time_ms: u32) void {
    if (task_ctrl_tbl.table[task_ctrl_tbl.runningPrio].active_tasks.head) |c_task| {
        c_task._data.blocked_time = time_ms;
        task_ctrl_tbl.removeActive(@volatileCast(c_task));
        task_ctrl_tbl.addYeilded(@volatileCast(c_task));
        ARCH.runScheduler();
    }
}
