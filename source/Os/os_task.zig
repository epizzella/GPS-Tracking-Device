pub const Task = struct {
    stack: []u32,
    stack_ptr: u32,
    subroutine: *const fn () callconv(.C) void,
    blocked_time: u32,
    priority: u5,
    towardTail: ?*Task,
    towardHead: ?*Task,
};
