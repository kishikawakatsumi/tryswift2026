/// BGM player using PWM buzzer on GP20.
///
/// Note advancement is driven by SysTick interrupt (1ms), not the
/// cooperative loop. This ensures notes change at precise times even
/// during heavy I2C display transfers.
enum Music {
  private static let buzzerPin: UInt32 = 20
  private static let pwmSlice: UInt32 = 2

  nonisolated(unsafe) private static var noteIndex = 0
  nonisolated(unsafe) private static var noteStartTick: UInt32 = 0
  nonisolated(unsafe) private static var playing = false
  nonisolated(unsafe) private static var inGap = false

  private static let noteCount = 40

  static func noteData(_ i: Int) -> UInt32 {
    switch i {
    case 0: return (659 << 16) | 420
    case 1: return (494 << 16) | 210
    case 2: return (523 << 16) | 210
    case 3: return (587 << 16) | 420
    case 4: return (523 << 16) | 210
    case 5: return (494 << 16) | 210
    case 6: return (440 << 16) | 420
    case 7: return (440 << 16) | 210
    case 8: return (523 << 16) | 210
    case 9: return (659 << 16) | 420
    case 10: return (587 << 16) | 210
    case 11: return (523 << 16) | 210
    case 12: return (494 << 16) | 420
    case 13: return (494 << 16) | 210
    case 14: return (523 << 16) | 210
    case 15: return (587 << 16) | 420
    case 16: return (659 << 16) | 420
    case 17: return (523 << 16) | 420
    case 18: return (440 << 16) | 420
    case 19: return (440 << 16) | 420
    case 20: return 210
    case 21: return (587 << 16) | 420
    case 22: return (698 << 16) | 210
    case 23: return (880 << 16) | 420
    case 24: return (784 << 16) | 210
    case 25: return (698 << 16) | 210
    case 26: return (659 << 16) | 630
    case 27: return (523 << 16) | 210
    case 28: return (659 << 16) | 420
    case 29: return (587 << 16) | 210
    case 30: return (523 << 16) | 210
    case 31: return (494 << 16) | 420
    case 32: return (494 << 16) | 210
    case 33: return (523 << 16) | 210
    case 34: return (587 << 16) | 420
    case 35: return (659 << 16) | 420
    case 36: return (523 << 16) | 420
    case 37: return (440 << 16) | 420
    case 38: return (440 << 16) | 420
    default: return 420
    }
  }

  static func initialize() {
    PWM.initialize(pin: buzzerPin)
    let divReg = Register(address: 0x4005_0000 + pwmSlice &* 0x14 + 0x04)
    divReg.store(16 << 4)
    noteIndex = 0
    noteStartTick = SysTick._tick
    inGap = false
    setPlaying(true)
    playCurrentNote()
  }

  /// Called from SysTick interrupt handler every 1ms.
  /// Must be very fast: just checks timing and writes PWM registers.
  /// Uses _tick directly (not the volatile-read property) since we're
  /// already in the interrupt that updates it.
  /// Volatile read of `playing` — prevents the compiler from caching
  /// the value across SysTick interrupt invocations.
  private static var isPlaying: Bool {
    withUnsafePointer(to: &playing) { ptr in
      UnsafeRawPointer(ptr).loadUnaligned(as: Bool.self)
    }
  }

  /// Volatile write of `playing`.
  private static func setPlaying(_ value: Bool) {
    withUnsafeMutablePointer(to: &playing) { ptr in
      UnsafeMutableRawPointer(ptr).storeBytes(of: value, as: Bool.self)
    }
  }

  static func advanceInInterrupt() {
    if !isPlaying { return }
    let now = SysTick._tick
    let elapsed = now &- noteStartTick

    if inGap {
      if elapsed >= 20 {
        noteIndex += 1
        if noteIndex >= noteCount { noteIndex = 0 }
        noteStartTick = now
        inGap = false
        playCurrentNote()
      }
      return
    }

    let duration = noteData(noteIndex) & 0xFFFF
    if elapsed >= duration {
      stopTone()
      noteStartTick = now
      inGap = true
    }
  }

  private static func playCurrentNote() {
    let freq = noteData(noteIndex) >> 16
    if freq == 0 { stopTone() } else {
      let top = 7_812_500 / freq
      PWM.setTop(slice: pwmSlice, top: top)
      PWM.setDuty(pin: buzzerPin, duty: top / 2)
    }
  }

  private static func stopTone() { PWM.setDuty(pin: buzzerPin, duty: 0) }

  static func stop() {
    setPlaying(false)
    stopTone()
  }
}
