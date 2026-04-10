/// Default exception handler that halts the processor.
@c
func defaultHandler() {
  while true {}
}

/// SysTick interrupt handler (fires every 1ms).
/// Handles two time-critical tasks directly in interrupt context:
///   1. Increment millisecond counter
///   2. Advance BGM (check note duration, switch PWM frequency)
/// Both are very fast (a few register reads/writes).
@c
func sysTickHandler() {
  SysTick._tick &+= 1
  Music.advanceInInterrupt()
}

/// GPIO bank 0 interrupt handler (IRQ13).
/// Captures button presses immediately, even during I2C flush.
@c
func gpioInterruptHandler() {
  ButtonISR.handle()
}

/// Entry point called by the hardware on reset (via the vector table).
@c
func resetHandler() {
  initializeMemorySections()
  Application.main()
}

/// ARM Cortex-M0+ vector table.
/// Entries 0-15: system exceptions. Entries 16+: peripheral IRQs.
/// IO_BANK0 is IRQ13 = entry 29.
@used
@section(".vector")
let vectorTable:
  (
    UInt32,  // 0:  Initial Stack Pointer
    @convention(c) () -> Void,  // 1:  Reset
    @convention(c) () -> Void,  // 2:  NMI
    @convention(c) () -> Void,  // 3:  HardFault
    @convention(c) () -> Void,  // 4:  Reserved
    @convention(c) () -> Void,  // 5:  Reserved
    @convention(c) () -> Void,  // 6:  Reserved
    @convention(c) () -> Void,  // 7:  Reserved
    @convention(c) () -> Void,  // 8:  Reserved
    @convention(c) () -> Void,  // 9:  Reserved
    @convention(c) () -> Void,  // 10: Reserved
    @convention(c) () -> Void,  // 11: SVCall
    @convention(c) () -> Void,  // 12: Reserved
    @convention(c) () -> Void,  // 13: Reserved
    @convention(c) () -> Void,  // 14: PendSV
    @convention(c) () -> Void,  // 15: SysTick
    @convention(c) () -> Void,  // 16: IRQ0  (TIMER_0)
    @convention(c) () -> Void,  // 17: IRQ1  (TIMER_1)
    @convention(c) () -> Void,  // 18: IRQ2  (TIMER_2)
    @convention(c) () -> Void,  // 19: IRQ3  (TIMER_3)
    @convention(c) () -> Void,  // 20: IRQ4  (PWM_WRAP)
    @convention(c) () -> Void,  // 21: IRQ5  (USBCTRL)
    @convention(c) () -> Void,  // 22: IRQ6  (XIP)
    @convention(c) () -> Void,  // 23: IRQ7  (PIO0_0)
    @convention(c) () -> Void,  // 24: IRQ8  (PIO0_1)
    @convention(c) () -> Void,  // 25: IRQ9  (PIO1_0)
    @convention(c) () -> Void,  // 26: IRQ10 (PIO1_1)
    @convention(c) () -> Void,  // 27: IRQ11 (DMA_0)
    @convention(c) () -> Void,  // 28: IRQ12 (DMA_1)
    @convention(c) () -> Void  // 29: IRQ13 (IO_BANK0)
  ) = (
    0x2004_0000,
    resetHandler,
    defaultHandler,
    defaultHandler,
    defaultHandler,
    defaultHandler,
    defaultHandler,
    defaultHandler,
    defaultHandler,
    defaultHandler,
    defaultHandler,
    defaultHandler,
    defaultHandler,
    defaultHandler,
    defaultHandler,
    sysTickHandler,
    defaultHandler,  // IRQ0
    defaultHandler,  // IRQ1
    defaultHandler,  // IRQ2
    defaultHandler,  // IRQ3
    defaultHandler,  // IRQ4
    defaultHandler,  // IRQ5
    defaultHandler,  // IRQ6
    defaultHandler,  // IRQ7
    defaultHandler,  // IRQ8
    defaultHandler,  // IRQ9
    defaultHandler,  // IRQ10
    defaultHandler,  // IRQ11
    defaultHandler,  // IRQ12
    gpioInterruptHandler  // IRQ13: IO_BANK0
  )
