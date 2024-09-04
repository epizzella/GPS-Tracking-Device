pub const Task = struct {
    stack: []u32,
    stack_ptr: u32,
    task_handler: *const fn () callconv(.C) void,
    blocked_time: u32,
    priority: u5,
    towardTail: ?*Task,
    towardHead: ?*Task,
};
