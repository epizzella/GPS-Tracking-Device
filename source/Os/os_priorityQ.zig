const Task = @import("os_task.zig").Task;

const MAX_PRIO_LEVEL = 33; //32 user accessable priority levels + idle task at lowest priority level
const IDLE_PRIORITY_LEVEL: u32 = 32; //idle task is the lowest priority.
const PRIO_ADJUST: u5 = 31;

pub var taskTable: TaskControlTable = .{};
const one: u32 = 1;

const TaskControlTable = struct {
    table: [MAX_PRIO_LEVEL]TaskStateQ = [_]TaskStateQ{.{}} ** MAX_PRIO_LEVEL,
    readyMask: u32 = 0, //mask of ready tasks
    runningPrio: u32 = 0xffffffff, //priority level of the currently running task

    ///Add task to the active task queue
    pub fn addActive(self: *TaskControlTable, task: *Task) void {
        self.table[task.priority].active_tasks.append(task);
        self.readyMask |= (one << (PRIO_ADJUST - task.priority));
    }

    ///Add task to the yielded task queue
    pub fn addYeilded(self: *TaskControlTable, task: *Task) void {
        self.table[task.priority].yielded_task.append(task);
    }

    ///Add task to the suspended task queue
    pub fn addSuspended(self: TaskControlTable, task: *Task) void {
        self.table[task.prioirty].suspended_tasks.append(task);
    }

    ///Remove task from the active task queue
    pub fn removeActive(self: *TaskControlTable, task: *Task) void {
        _ = self.table[task.priority].active_tasks.remove(task);
        if (self.table[task.priority].active_tasks.head == null) {
            self.readyMask &= ~(one << (PRIO_ADJUST - task.priority));
        }
    }

    ///Remove task from the yielded task queue
    pub fn removeYielded(self: *TaskControlTable, task: *Task) void {
        _ = self.table[task.priority].yielded_task.remove(task);
    }

    ///Remove task from the suspended task queue
    pub fn removeSuspended(self: *TaskControlTable, task: *Task) void {
        self.table[task.prioirty].suspended_tasks.remove(task);
    }

    pub fn setRunningPriority(self: *TaskControlTable, prio: u32) void {
        self.runningPrio = prio;
    }

    pub fn cycleActive(self: *TaskControlTable) void {
        if (self.runningPrio < MAX_PRIO_LEVEL) {
            self.table[self.runningPrio].active_tasks.headToTail();
        }
    }

    pub fn getNextReadyTask(self: *TaskControlTable) *Task {
        var ready: u32 = 0xffffffff;
        const ready_msk = self.readyMask;

        asm volatile ("clz    %[ready], %[mask]"
            : [ready] "=l" (ready), //return
            : [mask] "l" (ready_msk), //param
        );

        self.runningPrio = ready;

        return self.table[ready].active_tasks.head.?;
    }

    pub fn updateTasksDelay(self: *TaskControlTable) void {
        for (&self.table) |*taskState| {
            if (taskState.yielded_task.head) |head| {
                var task = head;
                while (true) { //iterate over the priority level list

                    if (task.blocked_time == 0) {
                        @breakpoint();
                    }

                    task.blocked_time -= 1; //todo: add a varaible for the system clock period
                    if (task.blocked_time == 0) {
                        self.removeYielded(task);
                        self.addActive(task);
                    }

                    if (task.to_tail) |next| {
                        task = next;
                    } else {
                        break;
                    }
                }
            }
        }
    }

    pub fn addIdleTask(self: *TaskControlTable, idle_task: *Task) void {
        self.table[IDLE_PRIORITY_LEVEL].active_tasks.append(idle_task);
    }
};

const TaskStateQ = struct {
    active_tasks: taskQueue = .{},
    yielded_task: taskQueue = .{},
    suspended_tasks: taskQueue = .{},
};

const taskQueue = struct {
    head: ?*Task = null,
    tail: ?*Task = null,
    elements: u32 = 0,

    ///Add a task to the end of the queue
    pub fn append(self: *taskQueue, task: *Task) void {
        if (self.head == null) {
            self.head = task;
            self.tail = task;
        } else {
            if (self.tail) |tail| {
                task.to_head = tail;
                tail.to_tail = task;
                task.to_tail = null;
            }
        }

        self.tail = task;
        self.elements += 1;
    }

    ///Pop the head task from the queue
    pub fn pop(self: *taskQueue) ?*Task {
        var rtn: ?*Task = null;
        if (self.head) |head| {
            rtn = head;
            head = head.to_tail;
            head.to_head = null;
            rtn.?.to_tail = null;
            if (self.elements == 0) {
                asm volatile ("BKPT");
            }
            self.elements -= 1;
        }
        return rtn;
    }

    ///Returns true if the specified task is contained in the queue
    pub fn contains(self: taskQueue, task: *Task) bool {
        var rtn = false;
        if (self.head) |head| {
            var current_task: *Task = head;
            while (true) {
                if (current_task == task) {
                    rtn = true;
                    break;
                }
                if (current_task.to_tail) |next| {
                    current_task = next;
                } else {
                    break;
                }
            }
        }

        return rtn;
    }

    ///Removes the specified task from the queue.  Returns false if the task is not contained in the queue.
    pub fn remove(self: *taskQueue, task: *Task) bool {
        var rtn = false;

        if (self.contains(task)) {
            if (self.head == self.tail) { //list of 1
                self.head = null;
                self.tail = null;
            } else if (self.head == task) {
                if (task.to_tail) |towardTail| {
                    self.head = towardTail;
                    towardTail.to_head = null;
                }
            } else if (self.tail == task) {
                if (task.to_head) |towardHead| {
                    self.tail = towardHead;
                    towardHead.to_tail = null;
                }
            } else {
                if (task.to_head) |towardHead| {
                    towardHead.to_tail = task.to_tail;
                }
                if (task.to_tail) |towardTail| {
                    towardTail.to_head = task.to_head;
                }
            }

            task.to_head = null;
            task.to_tail = null;

            self.elements -= 1;
            rtn = true;
        }

        return rtn;
    }

    ///Move the head task control block to the tail position
    pub fn headToTail(self: *taskQueue) void {
        if (self.head != self.tail) {
            if (self.head != null and self.tail != null) {
                const temp = self.head;
                self.head.?.to_tail.?.to_head = null;
                self.head = self.head.?.to_tail;

                temp.?.to_tail = null;
                self.tail.?.to_tail = temp;
                temp.?.to_head = self.tail;
                self.tail = temp;
            }
        }
    }
};
