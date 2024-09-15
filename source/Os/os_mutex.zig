const OS_TASK = @import("os_task.zig");
const OS_CORE = @import("os_core.zig");
const ARCH = @import("arch/arm-cortex-m/common/arch.zig");

const TaskQueue = @import("util/task_queue.zig");
const Task = TaskQueue.TaskHandle;
const task_control = &OS_TASK.task_control;

pub var mutex_control_table: MutexControleTable = .{};

const MutexControleTable = struct {};

const Context = struct {
    owner: ?*Task = null,
    pending: TaskQueue = .{},
};

const Config = struct { name: []const u8, enable_priority_inheritance: bool = false };

pub const Mutex = struct {
    _name: []const u8,
    _context: Context,

    pub fn create_mutex(name: []const u8) Mutex {
        return Mutex{ ._name = name, ._context = .{} };
    }

    pub fn acquire(self: *Mutex) void {
        if (!OS_CORE._isOsStarted()) @breakpoint(); //TODO: return an error
        if (ARCH.interruptActive()) @breakpoint(); //TODO: return an error

        ARCH.criticalStart();
        if (self._context.owner) |owner| {
            //locked
            _ = owner; //TODO: add priority inheritance check

            if (task_control.popActive()) |active| {
                self._context.pending.insertSorted(active);
                ARCH.criticalEnd();
                ARCH.runScheduler();
                ARCH.criticalStart();
                if (active != task_control.table[task_control.runningPrio].active_tasks.head) @breakpoint();
            } else {
                @breakpoint();
                //TODO: return error
            }
        } else {
            //unlocked
            if (task_control.table[task_control.runningPrio].active_tasks.head) |c_task| {
                self._context.owner = c_task;
            } else {
                @breakpoint();
                //TODO: return error
            }
        }
        ARCH.criticalEnd();
    }

    pub fn release(self: *Mutex) void {
        if (!OS_CORE._isOsStarted()) @breakpoint(); //TODO: return an error
        if (ARCH.interruptActive()) @breakpoint(); //TODO: return an error

        ARCH.criticalStart();
        if (task_control.table[task_control.runningPrio].active_tasks.head) |c_task| {
            if (c_task == self._context.owner) {
                self._context.owner = self._context.pending.head;
                if (self._context.pending.pop()) |head| {
                    task_control.addActive(head);
                    if (head._data.priority < task_control.runningPrio) {
                        ARCH.criticalEnd();
                        ARCH.runScheduler();
                        ARCH.criticalStart();
                    }
                }
            } else {
                @breakpoint();
                //TODO: return an error
            }
        } else {
            @breakpoint();
            //TODO: return an error
        }
        ARCH.criticalEnd();
    }
};
