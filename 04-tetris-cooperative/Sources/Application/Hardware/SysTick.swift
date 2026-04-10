/// SysTick system timer, 24-bit down counter in the ARM core.
///
/// Note: SysTick registers are in the ARM Private Peripheral Bus (PPB)
/// and do NOT have RP2040's atomic SET/CLR/XOR aliases.
enum SysTick {
  private static let csr = Register(address: 0xE000_E010)  // Control and Status
  private static let rvr = Register(address: 0xE000_E014)  // Reload Value
  private static let cvr = Register(address: 0xE000_E018)  // Current Value

  /// Elapsed milliseconds since initialization.
  private(set) nonisolated(unsafe) static var milliseconds: UInt32 = 0

  /// Configures SysTick for 1ms ticks at 125MHz.
  static func initialize() {
    milliseconds = 0
    cvr.store(0)  // Clear counter and COUNTFLAG
    rvr.store(125_000 - 1)  // 1ms at 125MHz
    // ENABLE=1, TICKINT=0 (polling, no interrupt), CLKSOURCE=1 (processor clock)
    csr.store(0x5)
  }

  /// Updates the millisecond counter by polling COUNTFLAG.
  ///
  /// Call this frequently (e.g., at the top of the main loop).
  /// Each time COUNTFLAG is set, one millisecond has elapsed.
  static func update() {
    if csr.load() & (1 << 16) != 0 {
      milliseconds &+= 1
    }
  }

  /// Blocks for `ms` milliseconds by polling COUNTFLAG.
  static func delay(milliseconds ms: UInt32) {
    let target = milliseconds &+ ms
    while milliseconds < target {
      update()
    }
  }
}
