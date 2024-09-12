const ARCH = @import("arch/arm-cortex-m/common/arch.zig");
pub const TaskQueue = @import("util/linked_queue.zig").LinkedQueue(Task);

pub const Task = struct {
    stack: []u32,
    stack_ptr: u32,
    subroutine: *const fn () void,
    blocked_time: u32,
    priority: u5,
    name: []const u8,

    pub fn _create_task(config: TaskConfig) Task {
        const task = Task{
            .name = config.name,
            .stack = config.stack,
            .priority = config.priority,
            .subroutine = config.subroutine,
            .blocked_time = 0,
            .stack_ptr = @intFromPtr(&config.stack[config.stack.len - 16]),
        };

        task.stack.ptr[task.stack.len - 1] = 0x1 << 24; // xPSR
        task.stack.ptr[task.stack.len - 2] = @intFromPtr(task.subroutine); //PC

        return task;
    }
};

pub const TaskConfig = struct {
    name: []const u8,
    stack: []u32,
    subroutine: *const fn () void,
    priority: u5,
};

pub var task_control: TaskControl = .{};

const MAX_PRIO_LEVEL = 33; //32 user accessable priority levels + idle task at lowest priority level
const IDLE_PRIORITY_LEVEL: u32 = 32; //idle task is the lowest priority.
const PRIO_ADJUST: u5 = 31;

const one: u32 = 1;

const TaskControl = struct {
    table: [MAX_PRIO_LEVEL]TaskStateQ = [_]TaskStateQ{.{}} ** MAX_PRIO_LEVEL,
    readyMask: u32 = 0, //mask of ready tasks
    previousPrio: u32 = 0xffffffff, //priority of the previously running task
    runningPrio: u32 = 0xffffffff, //priority level of the currently running task

    export var current_task: ?*volatile TaskQueue.OsObject = null;
    export var next_task: *volatile TaskQueue.OsObject = undefined;

    ///Add task to the active task queue
    pub fn addActive(self: *TaskControl, task: *TaskQueue.OsObject) void {
        self.table[task._data.priority].active_tasks.append(task);
        self.readyMask |= one << (PRIO_ADJUST - task._data.priority);
    }

    ///Add task to the yielded task queue
    pub fn addYeilded(self: *TaskControl, task: *TaskQueue.OsObject) void {
        self.table[task._data.priority].yielded_task.append(task);
    }

    ///Add task to the suspended task queue
    pub fn addSuspended(self: TaskControl, task: *TaskQueue.OsObject) void {
        self.table[task._data.priority].suspended_tasks.append(task);
    }

    ///Remove task from the active task queue
    pub fn removeActive(self: *TaskControl, task: *TaskQueue.OsObject) void {
        _ = self.table[task._data.priority].active_tasks.remove(task);
        if (self.table[task._data.priority].active_tasks.head == null) {
            self.readyMask &= ~(one << (PRIO_ADJUST - task._data.priority));
        }
    }

    ///Remove task from the yielded task queue
    pub fn removeYielded(self: *TaskControl, task: *TaskQueue.OsObject) void {
        _ = self.table[task._data.priority].yielded_task.remove(task);
    }

    ///Remove task from the suspended task queue
    pub fn removeSuspended(self: *TaskControl, task: *TaskQueue.OsObject) void {
        self.table[task._data.priority].suspended_tasks.remove(task);
    }

    ///Pop the active task from its active queue
    pub fn popActive(self: *TaskControl) ?*TaskQueue.OsObject {
        const head = self.table[self.runningPrio].active_tasks.pop();
        if (self.table[self.runningPrio].active_tasks.head == null) {
            self.readyMask &= ~(one << (PRIO_ADJUST - self.runningPrio));
        }

        return head;
    }

    pub fn cycleActive(self: *TaskControl) void {
        if (self.runningPrio < MAX_PRIO_LEVEL) {
            self.table[self.runningPrio].active_tasks.headToTail();
        }
    }

    pub fn readyNextTask(self: *TaskControl) void {
        self.runningPrio = ARCH.getReadyTaskIndex(self.readyMask);
        next_task = self.table[self.runningPrio].active_tasks.head.?;
    }

    pub fn validSwitch(self: *TaskControl) bool {
        _ = self;
        return current_task != next_task;
    }

    pub fn updateTasksDelay(self: *TaskControl) void {
        for (&self.table) |*taskState| {
            if (taskState.yielded_task.head) |head| {
                var task = head;
                while (true) { //iterate over the priority level list

                    if (task._data.blocked_time == 0) {
                        @breakpoint();
                    }

                    task._data.blocked_time -= 1; //todo: add a varaible for the system clock period
                    if (task._data.blocked_time == 0) {
                        self.removeYielded(task);
                        self.addActive(task);
                    }

                    if (task._to_tail) |next| {
                        task = next;
                    } else {
                        break;
                    }
                }
            }
        }
    }

    pub fn addIdleTask(self: *TaskControl, idle_task: *TaskQueue.OsObject) void {
        self.table[IDLE_PRIORITY_LEVEL].active_tasks.append(idle_task);
    }
};

const TaskStateQ = struct {
    active_tasks: TaskQueue = .{},
    yielded_task: TaskQueue = .{},
    suspended_tasks: TaskQueue = .{},
};
