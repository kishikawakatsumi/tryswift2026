/// SysTick system timer, 24-bit down counter in the ARM core.
///
/// Interrupt-driven: sysTickHandler fires every 1ms and increments
/// the tick counter. The counter is read via pointer manipulation
/// to prevent the compiler from caching the value.
enum SysTick {
  private static let csr = Register(address: 0xE000_E010)
  private static let rvr = Register(address: 0xE000_E014)
  private static let cvr = Register(address: 0xE000_E018)

  /// Raw tick storage. Incremented by sysTickHandler.
  nonisolated(unsafe) static var _tick: UInt32 = 0

  /// Reads the tick counter via pointer to prevent compiler caching.
  static var milliseconds: UInt32 {
    withUnsafePointer(to: &_tick) { ptr in
      UnsafeRawPointer(ptr).loadUnaligned(as: UInt32.self)
    }
  }

  /// Configures SysTick for 1ms interrupt at 125MHz.
  static func initialize() {
    _tick = 0
    cvr.store(0)
    rvr.store(125_000 - 1)
    // ENABLE=1, TICKINT=1 (interrupt), CLKSOURCE=1 (processor clock)
    csr.store(0x7)
  }

  /// Blocks for `ms` milliseconds.
  static func delay(milliseconds ms: UInt32) {
    let target = milliseconds &+ ms
    while (target &- milliseconds) < 0x8000_0000 {}
  }
}
