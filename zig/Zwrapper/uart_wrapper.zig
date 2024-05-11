const hal = @import("hal_include.zig");

/// ZUart is zig wrapper for a C implemntation of a uart driver.
pub const ZUart = struct {
    m_uart_handle: *hal.stm32.UART_HandleTypeDef,

    /// Non blocking write.
    ///
    /// data: slice of data to write.
    pub fn write(self: *ZUart, data: []const u8) void {
        _ = hal.stm32.HAL_UART_Transmit_IT(self.m_uart_handle, data.ptr, data.len);
    }

    /// Starts a non blocking read.
    ///
    /// data: slice of the receiving data buffer.
    pub fn beginRead(self: *ZUart, data: []const u8) void {
        _ = hal.stm32.HAL_UART_Receive_IT(self.m_uart_handle, data.ptr, data.len);
    }

    /// Blocking write.
    ///
    /// data: slice of data to write; timeout: in milliseconds
    pub fn writeBlocking(self: *ZUart, data: []const u8, timeout: u32) void {
        _ = hal.stm32.HAL_UART_Transmit(self.m_uart_handle, data.ptr, @intCast(data.len), timeout);
    }

    /// Blocking read.
    ///
    /// data: slice of the receiving data buffer; timeout: in milliseconds
    pub fn readBlocking(self: *ZUart, data: []const u8, timeout: u32) void {
        _ = hal.stm32.readBlocking(self.m_uart_handle, data.ptr, data.len, timeout);
    }

    /// Register a callback for nonblocking read completion.
    ///
    /// receiverPtr: The callback function.
    ///
    /// WARNING! receiverPtr function will be called from the uart ISR.
    pub fn registerReceiver(self: *ZUart, receiverPtr: *u8) void {
        hal.stm32.HAL_UART_RegisterCallback(self.m_uart_handle, hal.stm32.HAL_UART_RX_COMPLETE_CB_ID, receiverPtr);
    }

    /// Unregisters uart callback.
    pub fn unregisterReceiver(self: *ZUart) void {
        hal.stm32.HAL_UART_UnRegisterCallback(self.m_uart_handle, hal.stm32.HAL_UART_RX_COMPLETE_CB_ID);
    }
};
