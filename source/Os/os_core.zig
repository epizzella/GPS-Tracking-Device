const os_priorityQ = @import("os_priorityQ.zig");
pub const Task = @import("os_task.zig").Task;

//---------------Public API Start---------------//

pub fn startOS() void {
    core_SHPR3.* |= (isr_lowest_priority << pendSV_SHPR3_offset); //Set the pendsv to the lowest priority to avoid context switch during ISR
    core_SHPR3.* &= ~(isr_lowest_priority << sysTick_SHPR3_offset); //Set sysTick to the highest priority.

    var idle_task = Task{
        .stack = &idle_stack,
        .stack_ptr = @intFromPtr(&idle_stack[idle_stack.len - 16]),
        .task_handler = &_idle_task_handler,
        .priority = 0, //Idle task priority is ignored
        .blocked_time = 0,
        .towardHead = null,
        .towardTail = null,
    };
    _init_stack(&idle_stack, idle_task.task_handler);
    os_priorityQ.taskTable.addIdleTask(&idle_task);

    _os_started = true;
    runScheduler(); //begin os

    //never reach here

    //for some unexplainable reason zig hates PendSV_Handler and always tries to optimize it away.
    forceISRInclusion(PendSV_Handler);

    while (true) {
        //TODO: only set this brake point if debugger is attached
        asm volatile ("BKPT");
    }
}

pub fn addTaskToOs(tcb: *Task) void {
    _init_stack(tcb.stack, tcb.task_handler);
    os_priorityQ.taskTable.addActive(tcb);
}

pub fn delay(time_ms: u32) void {
    if (_current_task) |c_task| {
        c_task.blocked_time = time_ms;
        os_priorityQ.taskTable.removeActive(@volatileCast(c_task));
        os_priorityQ.taskTable.addYeilded(@volatileCast(c_task));
        runScheduler();
    }
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
const core_SHPR3: *volatile u32 = @ptrFromInt(0xE000ED20);
const core_ICSR: *volatile u32 = @ptrFromInt(0xE000ED04);

const isr_lowest_priority: u32 = 0xFF;
const pendSV_SHPR3_offset: u32 = 16;
const sysTick_SHPR3_offset: u32 = 24;

fn forceISRInclusion(val: anytype) void {
    asm volatile (""
        :
        : [val] "m" (val),
        : "memory"
    );
}

const IDLE_STACK_SIZE: u32 = 50;
var idle_stack: [IDLE_STACK_SIZE]u32 = [_]u32{0xDEADC0DE} ** IDLE_STACK_SIZE;

fn _idle_task_handler() callconv(.C) void {
    while (true) {
        //idle
        //add a call back for the user to set
    }
}

//todo set both of these to the idle task
var _current_task: ?*volatile Task = null;
var _next_task: *volatile Task = undefined;
var _os_started: bool = false;

pub fn _schedule() void {
    _next_task = os_priorityQ.taskTable.getNextReadyTask();

    if (_current_task != _next_task) {
        core_ICSR.* |= 1 << 28; //run context switch
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
pub export fn SysTick_Handler() void {
    uwTick += 1; //adding 1 counts up at 1ms
    _tick();
}

pub export fn PendSV_Handler() void {
    _context_swtich();
}

pub export fn SVC_Handler() void {
    disableInterrupts();
    _schedule();
    enableInterrupts();
}
