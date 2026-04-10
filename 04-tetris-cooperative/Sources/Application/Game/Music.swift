/// BGM player using PWM buzzer on GP20.
///
/// Plays Korobeiniki (Tetris theme). Call advance() every game loop iteration.
enum Music {
  private static let buzzerPin: UInt32 = 20
  private static let pwmSlice: UInt32 = 2  // GP20 / 2 = slice 2

  nonisolated(unsafe) private static var noteIndex = 0
  nonisolated(unsafe) private static var noteStartMs: UInt32 = 0
  nonisolated(unsafe) private static var playing = false
  nonisolated(unsafe) private static var inGap = false

  private static let noteCount = 40

  static func noteData(_ i: Int) -> UInt32 {
    switch i {
    case 0: return (659 << 16) | 300
    case 1: return (494 << 16) | 150
    case 2: return (523 << 16) | 150
    case 3: return (587 << 16) | 300
    case 4: return (523 << 16) | 150
    case 5: return (494 << 16) | 150
    case 6: return (440 << 16) | 300
    case 7: return (440 << 16) | 150
    case 8: return (523 << 16) | 150
    case 9: return (659 << 16) | 300
    case 10: return (587 << 16) | 150
    case 11: return (523 << 16) | 150
    case 12: return (494 << 16) | 300
    case 13: return (494 << 16) | 150
    case 14: return (523 << 16) | 150
    case 15: return (587 << 16) | 300
    case 16: return (659 << 16) | 300
    case 17: return (523 << 16) | 300
    case 18: return (440 << 16) | 300
    case 19: return (440 << 16) | 300
    case 20: return 150
    case 21: return (587 << 16) | 300
    case 22: return (698 << 16) | 150
    case 23: return (880 << 16) | 300
    case 24: return (784 << 16) | 150
    case 25: return (698 << 16) | 150
    case 26: return (659 << 16) | 450
    case 27: return (523 << 16) | 150
    case 28: return (659 << 16) | 300
    case 29: return (587 << 16) | 150
    case 30: return (523 << 16) | 150
    case 31: return (494 << 16) | 300
    case 32: return (494 << 16) | 150
    case 33: return (523 << 16) | 150
    case 34: return (587 << 16) | 300
    case 35: return (659 << 16) | 300
    case 36: return (523 << 16) | 300
    case 37: return (440 << 16) | 300
    case 38: return (440 << 16) | 300
    default: return 300
    }
  }

  static func initialize() {
    PWM.initialize(pin: buzzerPin)
    let divReg = Register(address: 0x4005_0000 + pwmSlice &* 0x14 + 0x04)
    divReg.store(16 << 4)
    noteIndex = 0
    noteStartMs = SysTick.milliseconds
    playing = true
    inGap = false
    playCurrentNote()
  }

  static func advance() {
    if !playing { return }
    let elapsed = SysTick.milliseconds &- noteStartMs
    if inGap {
      if elapsed >= 20 {
        noteIndex += 1
        if noteIndex >= noteCount { noteIndex = 0 }
        noteStartMs = SysTick.milliseconds
        inGap = false
        playCurrentNote()
      }
      return
    }
    let duration = noteData(noteIndex) & 0xFFFF
    if elapsed >= duration {
      stopTone()
      noteStartMs = SysTick.milliseconds
      inGap = true
    }
  }

  private static func playCurrentNote() {
    let freq = noteData(noteIndex) >> 16
    if freq == 0 {
      stopTone()
    } else {
      let top = 7_812_500 / freq
      PWM.setTop(slice: pwmSlice, top: top)
      PWM.setDuty(pin: buzzerPin, duty: top / 2)
    }
  }

  private static func stopTone() { PWM.setDuty(pin: buzzerPin, duty: 0) }
  static func stop() {
    stopTone()
    playing = false
  }
}
