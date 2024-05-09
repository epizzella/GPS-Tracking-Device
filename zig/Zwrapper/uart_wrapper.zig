const uart_hal = @cImport("stm32f1xx_hal_uart.h");

/// ZUart is zig wrapper for a C implemntation of a uart driver.
pub const ZUart = struct {
    /// Init the struct with a uart handle.  Must be called before any other functions
    ///
    /// uart_handle: pointer to the uart mem mapped peripheral
    pub fn init(uart_handle: *uart_hal.UART_HandleTypeDef) void {
        m_uart_handle = uart_handle;
    }

    /// Non blocking write.
    ///
    /// data: slice of data to write.
    pub fn write(data: []u8) !void {
        const rsp = uart_hal.HAL_UART_Transmit_IT(&m_uart_handle, data.ptr, data.len);
        if (rsp > 0) {
            return error{};
        }
    }

    /// Starts a non blocking read.
    ///
    /// data: slice of the receiving data buffer.
    pub fn beginRead(data: []u8) error{WriteError} {
        const rsp = uart_hal.HAL_UART_Receive_IT(&m_uart_handle, data.ptr, data.len);
        if (rsp > 0) {
            return error{};
        }
    }

    /// Blocking write.
    ///
    /// data: slice of data to write; timeout: in milliseconds
    pub fn writeBlocking(data: []u8, timeout: u32) error{WriteError} {
        const rsp = uart_hal.HAL_UART_Transmit(&m_uart_handle, data.ptr, data.len, timeout);
        if (rsp > 0) {
            return error{};
        }
    }

    /// Blocking read.
    ///
    /// data: slice of the receiving data buffer; timeout: in milliseconds
    pub fn readBlocking(data: []u8, timeout: u32) error{WriteError} {
        const rsp = uart_hal.readBlocking(&m_uart_handle, data.ptr, data.len, timeout);
        if (rsp > 0) {
            return error{};
        }
    }

    /// Register a callback for nonblocking read completion.
    ///
    /// receiverPtr: The callback function.
    ///
    /// WARNING! receiverPtr function will be called from the uart ISR.
    pub fn registerReceiver(receiverPtr: *u8) void {
        uart_hal.HAL_UART_RegisterCallback(&m_uart_handle, uart_hal.HAL_UART_RX_COMPLETE_CB_ID, receiverPtr);
    }

    /// Unregisters uart callback.
    pub fn unregisterReceiver() void {
        uart_hal.HAL_UART_UnRegisterCallback(&m_uart_handle, uart_hal.HAL_UART_RX_COMPLETE_CB_ID);
    }

    var m_uart_handle: *uart_hal.UART_HandleTypeDef = undefined;
};
