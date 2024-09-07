pub const Task = struct {
    stack: []u32,
    stack_ptr: u32,
    subroutine: *const fn () void,
    blocked_time: u32,
    priority: u5,
    name: []const u8,
    to_tail: ?*Task,
    to_head: ?*Task,
};
