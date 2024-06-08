const std = @import("std");

const core_SHPR3: *u32 = @ptrFromInt(0xE000ED20);
const core_ICSR: *u32 = @ptrFromInt(0xE000ED04);

const pendsv_lowest_priority: u32 = 0xFF00;

pub const os_error = error{
    OS_MEM_ALIGNMENT, //task stack is not memory aligned
};

var idle_stack: [50]u32 = undefined;
fn idle_task_handler() callconv(.C) void {
    while (true) {
        //idle
    }
}

export var current_task: ?*volatile Task = null;
export var next_task: *volatile Task = undefined;

const max_tasks = 31 + 1;
var tasks = [_]?Task{null} ** max_tasks;
var task_index: u8 = 0;

var os_started: bool = false;

pub fn start() void {
    std.mem.doNotOptimizeAway(idle_task_handler);

    Task.create_task(&idle_stack, &idle_task_handler, 31);
    var local_next_task: *volatile Task = undefined;
    std.mem.doNotOptimizeAway(local_next_task);

    core_SHPR3.* |= pendsv_lowest_priority; //lowest priority to avoid context switch during ISR
    if (tasks[0] != null) {
        local_next_task = @ptrCast(&tasks[0]);
    } else {
        local_next_task = @ptrCast(&tasks[max_tasks - 1]); //idle task
    }

    current_task = local_next_task;
    os_started = true;
    current_task.?.*.task_handler();
    //schedule();
    //core_ICSR.* |= 1 << 28; //trigger pendSV
}

pub fn onIdle() void {}

var last_time: u32 = 0;
pub fn schedule() void {
    disableInterrupts();
    next_task = getNextTask();
    if (current_task != next_task) {
        core_ICSR.* |= 1 << 28; //trigger pendSV
    }

    enableInterrupts();
}

fn getNextTask() *Task {
    var rtn_task: *Task = @ptrCast(&tasks[max_tasks - 1]);
    for (&tasks) |*task| {
        if (task.* != null) {
            if (task.*.?.state == task_state.active) {
                rtn_task = @ptrCast(task);
                break;
            }
        }
    }
    return rtn_task;
}

const task_state = enum(u32) {
    active,
    suspended,
    blocked,
};

pub const Task = extern struct {
    stack_ptr: [*]u32,
    stack_start: [*]u32,
    //stack_length: u32,
    task_handler: *const fn () callconv(.C) void,
    state: task_state,
    blocked_time: u32,
    priority: u8,

    ///Create a task and add it to the OS
    pub fn create_task(
        stack: []u32,
        task_handler: *const fn () callconv(.C) void,
        priority: u8,
    ) void {
        stack.ptr[stack.len - 1] = 0x1 << 24; // xPSR
        stack.ptr[stack.len - 2] = @intFromPtr(task_handler); //PC
        stack.ptr[stack.len - 3] = 0x0E0E0E0E; // LR
        stack.ptr[stack.len - 4] = 0x0C0C0C0C; // R12
        stack.ptr[stack.len - 5] = 0x03030303; // R3
        stack.ptr[stack.len - 6] = 0x02020202; // R2
        stack.ptr[stack.len - 7] = 0x01010101; // R1
        stack.ptr[stack.len - 8] = 0x00000000; // R0
        stack.ptr[stack.len - 9] = 0x0B0B0B0B; // R11
        stack.ptr[stack.len - 10] = 0x0A0A0A0A; // R10
        stack.ptr[stack.len - 11] = 0x09090909; // R9
        stack.ptr[stack.len - 12] = 0x08080808; // R8
        stack.ptr[stack.len - 13] = 0x07070707; // R7
        stack.ptr[stack.len - 14] = 0x06060606; // R6
        stack.ptr[stack.len - 15] = 0x05050505; // R5
        stack.ptr[stack.len - 16] = 0x04040404; // R4

        //initalize remaining stack space
        for (stack[0 .. stack.len - 17]) |*mem| {
            mem.* = 0xDEADC0DE;
        }

        tasks[priority] = Task{
            .stack_start = stack.ptr,
            .stack_ptr = stack.ptr + stack.len - 16,
            .task_handler = task_handler,
            .priority = priority,
            .state = task_state.active,
            .blocked_time = 0,
        };

        //else throw an error

        //return tasks[total_tasks - 1];
    }
};

pub inline fn enableInterrupts() void {
    asm volatile ("CPSIE    I");
}

pub inline fn disableInterrupts() void {
    asm volatile ("CPSID    I");
}

pub inline fn context_swtich() void {
    asm volatile ("                                 \n" ++
            "  CPSID    I                           \n" ++
            "  cmp.w %[curr_task], #0               \n" ++ //if current_task != null
            "  beq.n SpEqlNextSp                    \n" ++
            "  PUSH     {r4-r11}                    \n" ++ //push registers r4-r11 on the stack
            "  STR      sp, [%[curr_task],#0x00]    \n" ++ //save the current stack pointer in current_task
            "SpEqlNextSp:                           \n" ++
            "  LDR      sp, [%[next_task],#0x00]    \n" //Set stack pointer to next_task stack pointer
        : //no return
        : [curr_task] "l" (current_task),
          [next_task] "l" (next_task),
    );

    current_task = next_task;

    asm volatile ("                     \n" ++
            "  POP      {r4-r11}        \n" ++ //pop registers r4-r11
            "  CPSIE    I               \n" ++ //enable interrupts
            "  BX       lr              \n" //return to the next thread
    );
}

pub fn delay(time_ms: u32) void {
    current_task.?.blocked_time = time_ms;
    current_task.?.state = task_state.blocked;
    schedule();
}

var tick_count: u32 = 0;
pub inline fn tick() void {
    tick_count += 1;
    updateTasksDelay();
    if (os_started) {
        schedule();
    }
}

fn updateTasksDelay() void {
    for (&tasks) |*task| {
        if (task.* != null and task.*.?.blocked_time > 0) {
            task.*.?.blocked_time -= 1;
            if (task.*.?.blocked_time == 0) {
                task.*.?.state = task_state.active;
            }
        }
    }
}
