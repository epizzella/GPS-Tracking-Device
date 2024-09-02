//const Task = @import("os_task.zig").Task;

const MAX_PRIO_LEVEL = 33; //32 user accessable priority levels + idle task at lowest priority level
const PRIO_ADJUST: u5 = 31;
const IDLE_PRIO_LEVEL = 32;

pub var taskTable: TaskControlTable = .{};
const one: u32 = 1;

const TaskControlTable = struct {
    table: [MAX_PRIO_LEVEL]TaskStateQ = [_]TaskStateQ{.{}} ** MAX_PRIO_LEVEL,
    readyMask: u32 = 0, //mask of ready tasks
    runningPrio: u32 = 0xffffffff, //priority level of the currently running task

    ///Add tcb to the active task queue
    pub fn addActive(self: *TaskControlTable, tcb: *TaskCtrlBlk) void {
        self.table[tcb.priority].active_tasks.append(tcb);
        self.readyMask |= (one << @intCast(PRIO_ADJUST - tcb.priority));
    }

    ///Add tcb to the yielded tcb queue
    pub fn addYeilded(self: *TaskControlTable, tcb: *TaskCtrlBlk) void {
        self.table[tcb.priority].yielded_task.append(tcb);
    }

    ///Add tcb to the suspended tcb queue
    pub fn addSuspended(self: TaskControlTable, tcb: *TaskCtrlBlk) void {
        self.table[tcb.prioirty].suspended_tasks.append(tcb);
    }

    ///Remove tcb from the active tcb queue
    pub fn removeActive(self: *TaskControlTable, tcb: *TaskCtrlBlk) void {
        _ = self.table[tcb.priority].active_tasks.remove(tcb);
        if (self.table[tcb.priority].active_tasks.head == null) {
            self.readyMask &= ~(one << (PRIO_ADJUST - tcb.priority));
        }
    }

    ///Remove tcb from the yielded tcb queue
    pub fn removeYielded(self: *TaskControlTable, tcb: *TaskCtrlBlk) void {
        _ = self.table[tcb.priority].yielded_task.remove(tcb);
    }

    ///Remove tcb from the suspended tcb queue
    pub fn removeSuspended(self: *TaskControlTable, tcb: *TaskCtrlBlk) void {
        self.table[tcb.prioirty].suspended_tasks.remove(tcb);
    }

    pub fn setRunningPriority(self: *TaskControlTable, prio: u32) void {
        self.runningPrio = prio;
    }

    pub fn getNextReadyTask(self: *TaskControlTable) *TaskCtrlBlk {
        var ready: u32 = 0xffffffff;
        const ready_msk = self.readyMask;
        if (self.runningPrio < MAX_PRIO_LEVEL) {
            self.table[self.runningPrio].active_tasks.headToTail();
        }

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
                var tcb = head;
                while (true) { //iterate over the priority level list
                    // if (tcb.blocked_time == 100) {
                    //     @breakpoint();
                    // }

                    // if (tcb.blocked_time == 1) {
                    //     @breakpoint();
                    // }

                    tcb.blocked_time -= 1; //todo: add a varaible for the system clock period
                    if (tcb.blocked_time == 0) {
                        self.removeYielded(tcb);
                        self.addActive(tcb);
                        // _ = taskState.yielded_task.remove(tcb);
                        // taskState.active_tasks.append(tcb);
                    }

                    if (tcb.towardTail) |next| {
                        tcb = next;
                    } else {
                        break;
                    }
                }
            }
        }
    }
};

const TaskStateQ = struct {
    active_tasks: TcbQueue = .{},
    yielded_task: TcbQueue = .{},
    suspended_tasks: TcbQueue = .{},
};

const TcbQueue = struct {
    head: ?*TaskCtrlBlk = null,
    tail: ?*TaskCtrlBlk = null,
    elements: u32 = 0,

    ///Add a tcb to the end of the queue
    pub fn append(self: *TcbQueue, tcb: *TaskCtrlBlk) void {
        if (self.head == null) {
            self.head = tcb;
            self.tail = tcb;
        } else {
            if (self.tail) |tail| {
                tcb.towardHead = tail;
                tail.towardTail = tcb;
                tcb.towardTail = null;
            }
        }

        self.tail = tcb;
        self.elements += 1;
    }

    ///Pop the head tcb from the queue
    pub fn pop(self: *TcbQueue) ?*TaskCtrlBlk {
        var rtn: ?*TaskCtrlBlk = null;
        if (self.head) |head| {
            rtn = head;
            head = head.towardTail;
            head.towardHead = null;
            rtn.?.towardTail = null;
            self.elements -= 1;
        }
        return rtn;
    }

    ///Returns true if the specified tcb is contained in the queue
    pub fn contains(self: TcbQueue, tcb: *TaskCtrlBlk) bool {
        var rtn = false;
        if (self.head) |head| {
            var currentTcb: *TaskCtrlBlk = head;
            while (true) {
                if (currentTcb == tcb) {
                    rtn = true;
                    break;
                }
                if (currentTcb.towardTail) |next| {
                    currentTcb = next;
                } else {
                    break;
                }
            }
        }

        return rtn;
    }

    ///Removes the specified tcb from the queue.  Returns false if the tcb is not contained in the queue.
    pub fn remove(self: *TcbQueue, tcb: *TaskCtrlBlk) bool {
        var rtn = false;
        if (self.head != null) {
            if (self.contains(tcb)) {
                if (self.head == self.tail) { //list of 1
                    self.head = null;
                    self.tail = null;
                } else {
                    if (tcb.towardHead) |towardHead| {
                        towardHead.towardTail = tcb.towardTail;
                    }
                    if (tcb.towardTail) |towardTail| {
                        towardTail.towardHead = tcb.towardHead;
                    }
                }

                tcb.towardHead = null;
                tcb.towardTail = null;
                self.elements -= 1;
                rtn = true;
            }
        }
        return rtn;
    }

    ///Move the head task control block to the tail position
    pub fn headToTail(self: *TcbQueue) void {
        if (self.head != self.tail) {
            if (self.head != null and self.tail != null) {
                const temp = self.head;
                self.head.?.towardTail.?.towardHead = null;
                self.head = self.head.?.towardTail;

                temp.?.towardTail = null;
                self.tail.?.towardTail = temp;
                temp.?.towardHead = self.tail;
                self.tail = temp;
            }
        }
    }
};

pub const TaskCtrlBlk = struct {
    stack: []u32,
    //   stack_ptr: [*]u32,
    stack_ptr: u32,
    task_handler: *const fn () callconv(.C) void,
    blocked_time: u32,
    priority: u5,
    towardTail: ?*TaskCtrlBlk,
    towardHead: ?*TaskCtrlBlk,

    ///Suspend this task.  If this task is currently running it will immediately stop running.
    pub fn suspendMe(self: TaskCtrlBlk) void {
        taskTable.removeActive(&self);
        taskTable.addSuspended(&self);
        if (self == taskTable.table[taskTable.runningPrio].active_tasks.head.*) {
            runScheduler();
        }
    }

    ///Resume this task.  If this task is higher priority it will immediately preempt the running task.
    pub fn resumeMe(self: TaskCtrlBlk) void {
        taskTable.removeSuspended(&self);
        taskTable.addActive(&self);
        if (self.priority > taskTable.runningPrio) {
            runScheduler();
        }
    }

    ///Delay the task for a number of miliseconds.
    pub fn delayMe(self: TaskCtrlBlk, time_ms: u32) void {
        if (time_ms > 0) {
            self.blocked_time = time_ms;
            taskTable.removeActive(&self);
            taskTable.addYeilded(&self);
        }
        runScheduler();
    }
};

inline fn runScheduler() void {
    asm volatile ("SVC      #0");
}
