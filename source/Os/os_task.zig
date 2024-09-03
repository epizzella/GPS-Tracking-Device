pub const task_state = enum(u32) {
    active,
    suspended,
    blocked,
};

pub const Task = extern struct {
    stack_ptr: [*]u32,
    stack_start: [*]u32,
    task_handler: *const fn () callconv(.C) void,
    state: task_state,
    blocked_time: u32,
    priority: u8,
};
