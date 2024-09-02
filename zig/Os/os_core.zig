const std = @import("std");
const Task = @import("os_task.zig").Task;
const task_state = @import("os_task.zig").task_state;

pub const os_priorityQ = @import("os_priorityQ.zig");
const _Task = @import("os_priorityQ.zig").TaskCtrlBlk;
//const _taskControlTable = @import("os_priorityQ.zig").taskTable;
//var _taskControlTable = os_priorityQ.taskTable;

//---------------Public API Start---------------//

///Starts multi-tasking
pub fn start() void {
    std.mem.doNotOptimizeAway(idle_task_handler);

    create_task(&idle_stack, &idle_task_handler, max_tasks - 1);

    //Set the pendsv interrupt to the lowest priority to avoid context switch during ISR
    core_SHPR3.* |= isr_lowest_priority;

    for (&tasks) |*task| { //find the highest prioirty task
        if (task.* != null) {
            current_task = @ptrCast(task);
            break;
        }
    }

    os_started = true;
    current_task.?.*.task_handler(); //begin execution of the first task
}

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
}

pub fn delay(time_ms: u32) void {
    current_task.?.blocked_time = time_ms;
    current_task.?.state = task_state.blocked;
    runScheduler();
}

pub inline fn enableInterrupts() void {
    asm volatile ("CPSIE    I");
}

pub inline fn disableInterrupts() void {
    asm volatile ("CPSID    I");
}

pub inline fn runScheduler() void {
    asm volatile ("SVC      #0");
}

//---------------Public API End---------------//

var current_task: ?*volatile Task = null;
var next_task: *volatile Task = undefined;

const core_SHPR3: *u32 = @ptrFromInt(0xE000ED20);
const core_ICSR: *u32 = @ptrFromInt(0xE000ED04);

const isr_lowest_priority: u32 = 0xFF;
const pendSV_SHPR3_offset: u32 = 16;
const sysTick_SHPR3_offset: u32 = 24;

pub const os_error = error{
    OS_MEM_ALIGNMENT, //task stack is not memory aligned
};

var idle_stack: [50]u32 = undefined;
fn idle_task_handler() callconv(.C) void {
    while (true) {
        //idle
    }
}

const max_tasks = 31 + 1;
var tasks = [_]?Task{null} ** max_tasks;
var task_index: u8 = 0;

var os_started: bool = false;
var last_time: u32 = 0;
pub fn schedule() void {
    next_task = getNextTask();
    if (current_task != next_task) {
        core_ICSR.* |= 1 << 28; //run context switch
    }
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

//Call from inside PendSV_Handler
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

var tick_count: u32 = 0;
///Call from inside SysTick_Handler
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

//---- Unlimited tasks Start -------------

//todo set both of these to the idle task
var _current_task: ?*_Task = null;
var _next_task: *_Task = undefined;
var _os_started: bool = false;

inline fn _runScheduler() void {
    asm volatile ("SVC      #0");
}

pub fn _schedule() void {
    _next_task = os_priorityQ.taskTable.getNextReadyTask();
    if (_current_task != _next_task) {
        core_ICSR.* |= 1 << 28; //run context switch
    }
}

fn _init_stack(stack: []u32, task_handler: *const fn () callconv(.C) void) void {
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
}

pub fn _addTaskToOs(tcb: *_Task) void {
    _init_stack(tcb.stack, tcb.task_handler);
    os_priorityQ.taskTable.addActive(tcb);
}

pub fn _delay(time_ms: u32) void {
    if (_current_task) |c_task| {
        c_task.blocked_time = time_ms;
        os_priorityQ.taskTable.removeActive(c_task);
        os_priorityQ.taskTable.addYeilded(c_task);
        _runScheduler();
    }
    //   _current_task.blocked_time = time_ms;
    // os_priorityQ.taskTable.removeActive(_current_task);
    // os_priorityQ.taskTable.addYeilded(_current_task);
    // _runScheduler();
}

// fn _idle_task_handler() callconv(.C) void {
//     while (true) {
//         //idle
//         //add a call back for the user to set
//     }
// }

pub fn _startOS() void {
    // std.mem.doNotOptimizeAway(_idle_task_handler);
    // var _idle_stack: [50]u32 = [_]u32{0xDEADC0DE} ** 50;
    // var idleTask = os_priorityQ.TaskCtrlBlk{
    //     .stack = &_idle_stack,
    //     .stack_ptr = @ptrFromInt(@intFromPtr(&_idle_stack) + _idle_stack.len - 16),
    //     .task_handler = &_idle_task_handler,
    //     .priority = 32,
    //     .blocked_time = 0,
    //     .towardHead = null,
    //     .towardTail = null,
    // };

    // _init_stack(idleTask.stack, idleTask.task_handler);
    // _addTaskToOs(&idleTask);

    //Set the pendsv interrupt to the lowest priority to avoid context switch during ISR
    core_SHPR3.* |= (isr_lowest_priority << pendSV_SHPR3_offset);
    core_SHPR3.* &= ~(isr_lowest_priority << sysTick_SHPR3_offset);
    _next_task = os_priorityQ.taskTable.getNextReadyTask();
    _os_started = true;
    _runScheduler();

    // for (&os_priorityQ.taskTable.table) |*task| { //find the highest prioirty task and set it to the current task
    //     if (task.active_tasks.head) |current| {
    //         _current_task = current;
    //         os_priorityQ.taskTable.setRunningPriority(_current_task.priority);
    //         break;
    //     }
    // }

    // _os_started = true;
    // _current_task.task_handler(); //begin execution of the first task -- invoke the scheduler here instead?
    while (true) {}
}

var _tick_count: u32 = 0;
///Call from inside SysTick_Handler
pub inline fn _tick() void {
    _tick_count += 1;
    os_priorityQ.taskTable.updateTasksDelay();
    if (_os_started) {
        _schedule();
    }
}

const hal = @import("../Zwrapper/hal_include.zig").stm32;
const zuart = @import("../Zwrapper/uart_wrapper.zig").Zuart;

//Call from inside PendSV_Handler
pub inline fn _context_swtich() void {
    // const c_ptr = &_current_task.stack_ptr;
    // const n_ptr = &_next_task.stack_ptr;

    // const local_current = &_current_task;
    // _ = local_current;
    // //   std.mem.doNotOptimizeAway(local_current);
    // const local_next = _next_task;
    // //    std.mem.doNotOptimizeAway(local_next);

    // var tempAddr: [*]u32 = local_next.stack.ptr;

    // if (_current_task) |lct| {
    //     tempAddr = lct.stack.ptr;
    // }

    // const local_current_stack: *volatile [100]u32 = @ptrCast(tempAddr);
    // //   std.mem.doNotOptimizeAway(local_current_stack);

    // var local_next_stack: *volatile [100]u32 = @ptrCast(local_next.stack);
    //   std.mem.doNotOptimizeAway(local_next_stack);

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

    // asm volatile ("                                 \n" ++
    //         "  CPSID    I                           \n" ++ //disable interrupts
    //         "  cmp.w %[curr_task], #0               \n" ++ //if current_task != null
    //         "  beq.n SpEqlNextSp                    \n" ++
    //         "  PUSH     {r4-r11}                    \n" ++ //push registers r4-r11 on the stack
    //         "  STR      sp, [%[curr_task],#0x00]    \n" ++ //save the current stack pointer in current_task
    //         "SpEqlNextSp:                           \n" ++
    //         "  LDR      sp, [%[next_task],#0x00]    \n" //Set stack pointer to next_task stack pointer
    //     : //no return
    //     : [curr_task] "l" (c_ptr),
    //       [next_task] "l" (n_ptr),
    // );

    _current_task = _next_task;

    asm volatile ("                     \n" ++
            "  POP      {r4-r11}        \n" ++ //pop registers r4-r11
            "  CPSIE    I               \n" ++ //enable interrupts
            "  BX       lr              \n" //return to the next thread
    );
    // asm volatile ("                     \n" ++
    //         "  POP      {r4-r11}        \n" //pop registers r4-r11

    // );

    // asm volatile ("                     \n" ++
    //         "  CPSIE    I               \n" //enable interrupts
    // );
    // // std.mem.doNotOptimizeAway(local_next_stack);
    // // std.mem.doNotOptimizeAway(local_current_stack);
    // // std.mem.doNotOptimizeAway(local_next);
    // // std.mem.doNotOptimizeAway(local_current);
    // local_current_stack[99] += 1;
    // local_current_stack[99] -= 1;
    // local_next_stack[99] += 1;
    // local_next_stack[99] -= 1;
    // asm volatile ("                     \n" ++
    //         "  BX       lr              \n" //return to the next thread
    // );
}
