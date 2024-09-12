const OS_TASK = @import("os_task.zig");
const task_ctrl_tbl = &OS_TASK.task_control_table;
const OS_TYPES = @import("os_objects.zig");

const DEFAULT_IDLE_TASK_SIZE = 17;

pub const Task = OS_TASK.Task;

var os_config: OsConfig = .{};

pub fn _getOsConfig() OsConfig {
    return os_config;
}

pub fn _setOsConfig(config: OsConfig) void {
    if (!os_started) {
        os_config = config;
    }
}

fn idle_subroutine() void {
    while (true) {}
}

/// `idle_task_subroutine` - function run by the idle task. Replaces the default idle task.
/// `idle_stack_size` - number of words in the idle task stack.   Note:  if idle_task_subroutine is
/// provided idle_stack_size must be larger than 17.
/// `sysTick_callback` - function run at the beginning of the sysTick interrupt.
pub const OsConfig = struct {
    idle_task_subroutine: *const fn () void = &idle_subroutine,
    idle_stack_size: u32 = DEFAULT_IDLE_TASK_SIZE,
    sysTick_callback: ?*const fn () void = null,
};

var os_started: bool = false;
pub fn _setOsStarted() void {
    os_started = true;
}
pub fn _isOsStarted() bool {
    return os_started;
}
