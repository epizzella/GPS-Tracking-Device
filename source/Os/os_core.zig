const os_priorityQ = @import("os_priorityQ.zig");
pub const Task = @import("os_task.zig").Task;

//---------------Public API Start---------------//

pub fn startOS(comptime os_config: OsConfig) void {
    if (_os_started == false) {
        comptime {
            if (os_config.idle_stack_size < DEFAULT_IDLE_TASK_SIZE) {
                @compileError("Idle stack size cannont be less than the default value.");
            }

            if (os_config.idle_task_subroutine) {
                if (os_config.idle_stack_size <= DEFAULT_IDLE_TASK_SIZE) {
                    @compileError("Idle stack size must be greater than default size when an idle stack subroutine is provided.");
                }
            }
        }

        ARM_SHPR3.* |= ISR_LOWEST_PRIO; //Set the pendsv to the lowest priority to avoid context switch during ISR
        ARM_SHPR3.* &= ~SYSTICK_SHPR3_MSK; //Set sysTick to the highest priority.

        _os_config = os_config;

        var idle_stack: [os_config.idle_stack_size]u32 = [_]u32{0xDEADC0DE} ** os_config.idle_stack_size;
        var idle_task = Task{
            .stack = &idle_stack,
            .stack_ptr = @intFromPtr(&idle_stack[idle_stack.len - 16]),
            .subroutine = if (os_config.idle_task_subroutine != null) os_config.idle_task_subroutine else &_idle_subroutine,
            .priority = 0, //Idle task priority is ignored
            .blocked_time = 0,
            .towardHead = null,
            .towardTail = null,
        };
        _init_stack(&idle_stack, idle_task.subroutine);
        os_priorityQ.taskTable.addIdleTask(&idle_task);

        _os_started = true;
        runScheduler(); //begin os

        if ((ARM_DHCSR.* & C_DEBUGEN_MSK) > 0) {
            asm volatile ("BKPT");
        }

        unreachable;
    }
}

pub fn addTaskToOs(task: *Task) void {
    _init_stack(task.stack, task.subroutine);
    os_priorityQ.taskTable.addActive(task);
}

pub fn delay(time_ms: u32) void {
    if (_current_task) |c_task| {
        c_task.blocked_time = time_ms;
        os_priorityQ.taskTable.removeActive(@volatileCast(c_task));
        os_priorityQ.taskTable.addYeilded(@volatileCast(c_task));
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

var _os_config: OsConfig = .{};

const DEFAULT_IDLE_TASK_SIZE = 17;
pub const OsConfig = struct {
    idle_task_subroutine: ?*const fn () callconv(.C) void = null,
    idle_stack_size: u32 = DEFAULT_IDLE_TASK_SIZE,
    sysTick_callback: ?*const fn () callconv(.C) void = null,
};

fn forceISRInclusion(val: anytype) void {
    asm volatile (""
        :
        : [val] "m" (val),
        : "memory"
    );
}

inline fn runScheduler() void {
    asm volatile ("SVC      #0");
}

fn _idle_subroutine() callconv(.C) void {
    while (true) {}
}

//todo set both of these to the idle task
var _current_task: ?*volatile Task = null;
var _next_task: *volatile Task = undefined;
var _os_started: bool = false;

pub fn _schedule() void {
    _next_task = os_priorityQ.taskTable.getNextReadyTask();

    if (_current_task != _next_task) {
        ARM_ICSR.* |= 1 << 28; //run context switch
    }
}

///Call from inside SysTick_Handler
pub inline fn _tick() void {
    if (_os_started) {
        os_priorityQ.taskTable.updateTasksDelay();
        os_priorityQ.taskTable.cycleActive();
        _schedule();
    }
}

fn _init_stack(stack: []u32, subroutine: *const fn () callconv(.C) void) void {
    stack.ptr[stack.len - 1] = 0x1 << 24; // xPSR
    stack.ptr[stack.len - 2] = @intFromPtr(subroutine); //PC
}

//Call from inside PendSV_Handler
pub inline fn _context_swtich() void {
    asm volatile ("                                 \n" ++
            "  CPSID    I                           \n" ++ //disable interrupts
            "  cmp.w %[curr_task], #0               \n" ++ //if current_task != null
            "  beq.n SpEqlNextSp                    \n" ++
            "  PUSH     {r4-r11}                    \n" ++ //push registers r4-r11 on the stack
            "  STR      sp, [%[curr_task],#0x08]    \n" ++ //save the current stack pointer in current_task
            "SpEqlNextSp:                           \n" ++
            "  LDR      sp, [%[next_task],#0x08]    \n" //Set stack pointer to next_task stack pointer
        : //no return
        : [curr_task] "l" (_current_task),
          [next_task] "l" (_next_task),
    );

    _current_task = _next_task;

    asm volatile ("                     \n" ++
            "  POP      {r4-r11}        \n" ++ //pop registers r4-r11
            "  CPSIE    I               \n" ++ //enable interrupts
            "  BX       lr              \n" //return to the next thread
    );
}

extern var uwTick: c_uint;
export fn SysTick_Handler() void {
    uwTick += 1; //adding 1 counts up at 1ms
    if (_os_config.sysTick_callback) |callback| {
        callback();
    }
    _tick();
}

export fn PendSV_Handler() void {
    _context_swtich();
}

export fn SVC_Handler() void {
    criticalStart();
    _schedule();
    criticalEnd();
}
