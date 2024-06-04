const core_SHPR3: *u32 = @ptrFromInt(0xE000ED20);
const core_ICSR: *u32 = @ptrFromInt(0xE000ED04);

const pendsv_lowest_priority: u32 = 0xFF00;

pub const os_error = error{
    OS_MEM_ALIGNMENT, //task stack is not memory aligned
};

//var idle_stack: [50]u32 = undefined;
//fn idle_task_handler() void {}
//var idle_task: Task = undefined;

export var current_task: *volatile Task = undefined;
export var next_task: *volatile Task = undefined;

const max_tasks = 32 + 1;
var total_tasks: u32 = 0;

var tasks: [max_tasks]Task = undefined;
var task_index: u8 = 0;

var os_started: bool = false;

pub fn start() void {
    core_SHPR3.* |= pendsv_lowest_priority; //lowest priority to avoid context switch during ISR
    //   idle_task = Task.create_task(&idle_stack, &idle_task_handler, 255);
    current_task = @ptrFromInt(0x8000000);
    next_task = &tasks[0];
    os_started = true;
    core_ICSR.* |= 1 << 28; //trigger pendSV
}

pub fn onIdle() void {}

var last_time: u32 = 0;
pub fn schedule() void {
    disableInterrupts();
    const current_time: u32 = uwTick;

    if (((current_time - last_time) > 4000) or (current_task.state != task_state.active)) {
        last_time = current_time;
        task_index += 1;
        if (task_index >= total_tasks) {
            task_index = 0;
        }
        next_task = &tasks[task_index];
        core_ICSR.* |= 1 << 28; //trigger pendSV
    }
    enableInterrupts();
}

const task_state = enum(u32) {
    active,
    suspended,
    blocked,
};

pub const Task = extern struct {
    stack_ptr: [*]u32,
    stack_start: [*]u32,
    stack_length: u32,
    task_handler: *const fn () callconv(.C) void,
    state: task_state,
    blockeded_time: u32,
    priority: u8,

    ///Create a task and add it to the OS
    pub fn create_task(
        stack: []u32,
        task_handler: *const fn () callconv(.C) void,
        priority: u8,
    ) Task {
        //check that stack is memory aligned i.e. first 3 bits are 000
        //if (((@intFromPtr(stack.ptr) + stack.len) & 0x3) != 0) {
        //    return os_error.OS_MEM_ALIGNMENT;
        //}

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

        if (total_tasks < max_tasks) {
            tasks[total_tasks] = Task{
                .stack_start = stack.ptr,
                .stack_length = stack.len,
                .task_handler = task_handler,
                .priority = priority,
                .stack_ptr = stack.ptr + stack.len - 16,
                .state = task_state.active,
                .blockeded_time = 0,
            };
            total_tasks += 1;
        }
        //else throw an error

        return tasks[total_tasks - 1];
    }

    pub fn placeholder(self: Task) void {
        _ = self;
    }
};

//pub const Time = struct {};

pub inline fn enableInterrupts() void {
    asm volatile ("CPSIE    I");
}

pub inline fn disableInterrupts() void {
    asm volatile ("CPSID    I");
}

fn context_swtich() void {
    asm volatile ("                                 \n" ++
            "  CPSID    I                           \n" ++
            "cmp.w %[curr_task], #134217728         \n" ++ //if current_task != 0x8000000
            "beq.n SpEqlNextSp                      \n" ++
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
        : //no return
        : [curr_task] "l" (current_task),
          [next_task] "l" (next_task),
    );
}

pub fn delay(time_ms: u32) void {
    current_task.blockeded_time = time_ms;
    current_task.state = task_state.blocked;
    schedule();
}

var time: u32 = 0;
fn tick() void {
    time += 1;

    if (os_started) {
        schedule();
    }
}

extern var uwTick: c_uint;
export fn SysTick_Handler() void {
    uwTick += 1; //adding 1 counts up at 1ms
    tick();
}

export fn PendSV_Handler() void {
    context_swtich();
}
