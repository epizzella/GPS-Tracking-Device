const OS_TASK = @import("os_task.zig");
pub const Task = OS_TASK.Task;
const task_ctrl_tbl = &OS_TASK.task_control_table;
const OS_TYPES = @import("os_objects.zig");

//---------------Public API Start---------------//

pub fn create_task(config: OS_TASK.TaskConfig) OS_TYPES.TaskQueue.OsObject {
    return OS_TYPES.TaskQueue.OsObject{
        .name = config.name,
        ._data = Task._create_task(config),
    };
}

pub fn addTaskToOs(task: *OS_TASK.TaskQueue.OsObject) void {
    task_ctrl_tbl.addActive(task);
}

export var g_stack_offset: u32 = 0x08;
pub fn startOS(comptime config: OsConfig) void {
    if (os_started == false) {
        comptime {
            if (config.idle_stack_size < DEFAULT_IDLE_TASK_SIZE) {
                @compileError("Idle stack size cannont be less than the default stack size: " ++ DEFAULT_IDLE_TASK_SIZE);
            }

            if (config.idle_task_subroutine != null) {
                if (config.idle_stack_size <= DEFAULT_IDLE_TASK_SIZE) {
                    @compileError("Idle stack size must be greater than default size(" ++ DEFAULT_IDLE_TASK_SIZE ++ ") when an idle stack subroutine is provided");
                }
            }
        }

        ARM_SHPR3.* |= ISR_LOWEST_PRIO; //Set the pendsv to the lowest priority to avoid context switch during ISR
        ARM_SHPR3.* &= ~SYSTICK_SHPR3_MSK; //Set sysTick to the highest priority.

        os_config = config;

        var idle_stack: [config.idle_stack_size]u32 = [_]u32{0xDEADC0DE} ** config.idle_stack_size;

        var idle_task = create_task(.{
            .name = "idle task",
            .priority = 0, //Idle task priority is ignored
            .stack = &idle_stack,
            .subroutine = if (config.idle_task_subroutine) |user_idle| user_idle else &_idle_subroutine,
        });

        task_ctrl_tbl.addIdleTask(&idle_task);

        //Find offset to stack ptr as zig does not guarantee struct field order
        g_stack_offset = @abs(@intFromPtr(&idle_task._data.stack_ptr) -% @intFromPtr(&idle_task));

        os_started = true;
        runScheduler(); //begin os

        //if debugger is attached hit this breakpoint if we somehow return from os
        if ((ARM_DHCSR.* & C_DEBUGEN_MSK) > 0) {
            asm volatile ("BKPT");
        }

        unreachable;
    }
}

pub fn delay(time_ms: u32) void {
    if (task_ctrl_tbl.table[task_ctrl_tbl.runningPrio].active_tasks.head) |c_task| {
        c_task._data.blocked_time = time_ms;
        task_ctrl_tbl.removeActive(@volatileCast(c_task));
        task_ctrl_tbl.addYeilded(@volatileCast(c_task));
        runScheduler();
    }
}

///Enable Interrupts
pub inline fn criticalEnd() void {
    asm volatile ("CPSIE    I");
}

//Disable Interrupts
pub inline fn criticalStart() void {
    asm volatile ("CPSID    I");
}

//---------------Public API End---------------//
const ARM_SHPR3: *volatile u32 = @ptrFromInt(0xE000ED20);
const ARM_ICSR: *volatile u32 = @ptrFromInt(0xE000ED04);
const ARM_DHCSR: *volatile u32 = @ptrFromInt(0xE000EDF0);

const ISR_LOWEST_PRIO: u32 = 0xFF;
const PENDSV_SHPR3_MSK: u32 = ISR_LOWEST_PRIO << 16;
const SYSTICK_SHPR3_MSK: u32 = ISR_LOWEST_PRIO << 24;
const C_DEBUGEN_MSK: u32 = 0x1;

var os_config: OsConfig = .{};

const DEFAULT_IDLE_TASK_SIZE = 17;
pub const OsConfig = struct {
    idle_task_subroutine: ?*const fn () void = null,
    idle_stack_size: u32 = DEFAULT_IDLE_TASK_SIZE,
    sysTick_callback: ?*const fn () void = null,
};

fn forceISRInclusion(val: anytype) void {
    asm volatile (""
        :
        : [val] "m" (val),
        : "memory"
    );
}

pub inline fn runScheduler() void {
    asm volatile ("SVC      #0");
}

fn _idle_subroutine() callconv(.C) void {
    while (true) {}
}

//todo set both of these to the idle task
export var current_task: ?*volatile OS_TASK.TaskQueue.OsObject = null;
export var next_task: *volatile OS_TASK.TaskQueue.OsObject = undefined;

var os_started: bool = false;

fn schedule() void {
    next_task = task_ctrl_tbl.getNextReadyTask();

    if (current_task != next_task) {
        ARM_ICSR.* |= 1 << 28; //run context switch
    }
}

///Call from inside SysTick_Handler
inline fn tick() void {
    if (os_started) {
        task_ctrl_tbl.updateTasksDelay();
        task_ctrl_tbl.cycleActive();
        schedule();
    }
}

export fn SysTick_Handler() void {
    if (os_config.sysTick_callback) |callback| {
        callback();
    }
    tick();
}

export fn SVC_Handler() void {
    criticalStart();
    schedule();
    criticalEnd();
}
