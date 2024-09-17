const Self = @This();

pub fn coreInit(self: *Self) void {
    _ = self;
}

pub fn interruptActive(self: *Self) bool {
    _ = self;
    return false;
}

pub inline fn criticalEnd(self: *Self) void {
    _ = self;
}

//Enable Interrupts
pub inline fn criticalStart(self: *Self) void {
    _ = self;
}

//Disable Interrupts
pub inline fn runScheduler(self: *Self) void {
    _ = self;
}

pub inline fn runContextSwitch(self: *Self) void {
    _ = self;
}

pub inline fn isDebugAttached(self: *Self) bool {
    _ = self;
    return false;
}
