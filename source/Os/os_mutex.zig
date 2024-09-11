const OS_TASK = @import("os_task.zig");
const LinkedQueue = @import("util/linked_queue.zig").LinkedQueue(Task);
const Task = OS_TASK.TaskQueue.OsObject;
const task_ctrl_tbl = &OS_TASK.task_control_table;

pub var mutex_control_table: MutexControleTable = .{};

const MutexControleTable = struct {};

const Context = struct {
    locked: bool = false,
    owner: ?*Task = null,
    pending: LinkedQueue,
};

pub const Mutex = struct {
    name: []const u8,
    _context: Context,

    pub fn create_mutex(name: []const u8) Mutex {
        return Mutex{ .name = name, ._context = .{} };
    }

    pub fn pend(self: Mutex) void {
        if (task_ctrl_tbl.table[task_ctrl_tbl.runningPrio].active_tasks.head) |c_task| {
            if (self._context.locked) {
                task_ctrl_tbl.removeActive(@volatileCast(c_task));
                self._context.pending.append(c_task); //TODO: change to sorted insert
                asm volatile ("SVC      #0"); //run scheduler
            } else {
                self._context.locked = true;
                self._context.owner = c_task;
            }
        }
    }

    pub fn post(self: Mutex) void {
        if (task_ctrl_tbl.table[task_ctrl_tbl.runningPrio].active_tasks.head) |c_task| {
            _ = c_task;
        }
        _ = self;
    }
};
