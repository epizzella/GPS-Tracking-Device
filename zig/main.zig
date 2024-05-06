pub const RCC_APB2ENR: *u32 = @ptrFromInt(0x40021018);
pub const GPIOC_CRH: *u32 = @ptrFromInt(0x40011004);
pub const GPIOC_ODR: *u32 = @ptrFromInt(0x4001100C);

export fn main() void {
    RCC_APB2ENR.* |= @as(u32, 0x10); // Enable GPIOC clkGPIOC_CRH.* &= ~@as(u32, 0b1111 << 20);  // Clear all the bits relative to PC13
    GPIOC_CRH.* |= @as(u32, 0b0010 << 20); // Now set the desired configuration: Out PP, 2MHz
    while (true) {
        var i: u32 = 0;
        GPIOC_ODR.* ^= @as(u32, 0x2000); // Toggle the bit corresponding to GPIOC13
        while (i < 100_000) { // Wait a bit
            i += 1;
        }
    }
}
