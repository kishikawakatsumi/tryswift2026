/// GP2040-CE default Pico pin mapping:
/// GP02=Up  GP03=Down GP04=Right GP05=Left
/// GP06=B1  GP07=B2   GP08=R2    GP09=L2
/// GP10=B3  GP11=B4   GP12=R1    GP13=L1
/// GP14=Turbo         GP16=S1    GP17=S2
/// GP18=L3  GP19=R3   GP20=A1    GP21=A2
struct Buttons {
  // GP02-GP14, GP16-GP21 (GP15 unused)
  private static let pinMask: UInt32 = 0x003F_7FFC
  private static let debounceCount: UInt32 = 5

  private var stableState: UInt32 = 0
  private var candidateState: UInt32 = 0
  private var candidateCount: UInt32 = 0

  func initialize() {
    var pin: UInt32 = 2
    while pin <= 21 {
      if pin != 15 {
        SIO.disableOutput(pin)
        PadsBank.store(pin, 0x4A)  // IE | PUE | Schmitt
        IOBank.setFunction(pin, .sio)
      }
      pin &+= 1
    }
  }

  /// Returns debounced GPIO state. Active-high (1 = pressed).
  /// Each bit corresponds to its GPIO pin number.
  mutating func poll() -> UInt32 {
    let raw = SIO.readAll()
    let current = (~raw) & Self.pinMask

    if current == candidateState {
      candidateCount &+= 1
      if candidateCount >= Self.debounceCount {
        stableState = current
      }
    } else {
      candidateState = current
      candidateCount = 0
    }
    return stableState
  }
}
