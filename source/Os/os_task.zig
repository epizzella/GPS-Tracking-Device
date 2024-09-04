pub const task_state = enum(u32) {
    active,
    suspended,
    blocked,
};

pub const Task = struct {
    stack: []u32,
    stack_ptr: u32,
    task_handler: *const fn () callconv(.C) void,
    blocked_time: u32,
    priority: u5,
    towardTail: ?*Task,
    towardHead: ?*Task,

    // ///Suspend this task.  If this task is currently running it will immediately stop running.
    // pub fn suspendMe(self: TaskCtrlBlk) void {
    //     taskTable.removeActive(&self);
    //     taskTable.addSuspended(&self);
    //     if (self == taskTable.table[taskTable.runningPrio].active_tasks.head) {
    //         runScheduler();
    //     }
    // }

    // ///Resume this task.  If this task is higher priority it will immediately preempt the running task.
    // pub fn resumeMe(self: TaskCtrlBlk) void {
    //     taskTable.removeSuspended(&self);
    //     taskTable.addActive(&self);
    //     if (self.priority > taskTable.runningPrio) {
    //         runScheduler();
    //     }
    // }
};
