const hal = @import("hal_include.zig").stm32;
const halStatus = @import("hal_include.zig").HalStatus;

/// ZUart is zig wrapper for a C implemntation of a uart driver.
pub const Zuart = struct {
    m_uart_handle: *hal.UART_HandleTypeDef,

    /// Non blocking write.
    ///
    /// data: slice of data to write.
    pub fn write(self: *Zuart, data: []const u8) halStatus.errors!void {
        const status = hal.HAL_UART_Transmit_IT(self.m_uart_handle, data.ptr, data.len);
        try halStatus.StatusToErr(status);
    }

    /// Starts a non blocking read.
    ///
    /// data: slice of the receiving data buffer.
    pub fn beginRead(self: *Zuart, data: []const u8) halStatus.errors!void {
        const status = hal.HAL_UART_Receive_IT(self.m_uart_handle, data.ptr, data.len);
        try halStatus.StatusToErr(status);
    }

    /// Blocking write.
    ///
    /// data: slice of data to write; timeout: in milliseconds
    pub fn writeBlocking(self: *Zuart, data: []const u8, timeout: u32) halStatus.errors!void {
        const status = hal.HAL_UART_Transmit(self.m_uart_handle, data.ptr, @intCast(data.len), timeout);
        try halStatus.StatusToErr(status);
    }

    /// Blocking read.
    ///
    /// data: slice of the receiving data buffer; timeout: in milliseconds
    pub fn readBlocking(self: *Zuart, data: []const u8, timeout: u32) halStatus.errors!void {
        const status = hal.readBlocking(self.m_uart_handle, data.ptr, data.len, timeout);
        try halStatus.StatusToErr(status);
    }

    /// Register a callback for nonblocking read completion.
    ///
    /// receiverPtr: The callback function.
    ///
    /// WARNING! receiverPtr function will be called from the uart ISR.
    pub fn registerReceiver(self: *Zuart, receiverPtr: *u8) void {
        hal.HAL_UART_RegisterCallback(self.m_uart_handle, hal.HAL_UART_RX_COMPLETE_CB_ID, receiverPtr);
    }

    /// Unregisters uart callback.
    pub fn unregisterReceiver(self: *Zuart) void {
        hal.HAL_UART_UnRegisterCallback(self.m_uart_handle, hal.HAL_UART_RX_COMPLETE_CB_ID);
    }
};
