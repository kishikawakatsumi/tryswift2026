/// Nested Vectored Interrupt Controller (ARM Cortex-M0+).
///
/// Controls enabling, disabling, and pending of peripheral interrupts (IRQ0-IRQ31).
/// Note: NVIC registers do NOT have RP2040's atomic SET/CLR/XOR aliases.
enum NVIC {
  private static let iser = Register(address: 0xE000_E100)  // Interrupt Set-Enable
  private static let icer = Register(address: 0xE000_E180)  // Interrupt Clear-Enable
  private static let ispr = Register(address: 0xE000_E200)  // Interrupt Set-Pending
  private static let icpr = Register(address: 0xE000_E280)  // Interrupt Clear-Pending

  // RP2040 IRQ numbers (datasheet 2.3.2)
  enum IRQ: UInt32 {
    case timer0 = 0
    case timer1 = 1
    case timer2 = 2
    case timer3 = 3
    case uart0 = 20
    case uart1 = 21
    case io0 = 13  // GPIO bank 0 interrupt
  }

  /// Enables a peripheral interrupt.
  static func enable(_ irq: IRQ) {
    iser.store(1 << irq.rawValue)
  }

  /// Disables a peripheral interrupt.
  static func disable(_ irq: IRQ) {
    icer.store(1 << irq.rawValue)
  }

  /// Sets a pending interrupt (triggers it in software).
  static func setPending(_ irq: IRQ) {
    ispr.store(1 << irq.rawValue)
  }

  /// Clears a pending interrupt.
  static func clearPending(_ irq: IRQ) {
    icpr.store(1 << irq.rawValue)
  }
}
