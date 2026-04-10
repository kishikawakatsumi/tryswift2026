/// Button input via GPIO falling-edge interrupts.
///
/// The interrupt handler captures button presses immediately (even during
/// I2C flush) and stores them in a bitmask. The cooperative loop reads
/// and clears this bitmask each frame.
enum ButtonISR {
  // Bitmask of buttons pressed since last read.
  // Written by interrupt, read/cleared by cooperative loop.
  // Bit 0=left, 1=right, 2=A, 3=B, 4=up, 5=down
  nonisolated(unsafe) static var pressed: UInt8 = 0

  // Pin assignments
  private static let pinUp: UInt32 = 2
  private static let pinDown: UInt32 = 3
  private static let pinLeft: UInt32 = 4
  private static let pinRight: UInt32 = 5
  private static let pinA: UInt32 = 6
  private static let pinB: UInt32 = 7

  /// Configures GPIO falling-edge interrupts for all 6 buttons.
  static func initialize() {
    IOBank.enableInterrupt(pinUp, .fallingEdge)
    IOBank.enableInterrupt(pinDown, .fallingEdge)
    IOBank.enableInterrupt(pinLeft, .fallingEdge)
    IOBank.enableInterrupt(pinRight, .fallingEdge)
    IOBank.enableInterrupt(pinA, .fallingEdge)
    IOBank.enableInterrupt(pinB, .fallingEdge)
    NVIC.enable(.io0)
  }

  /// Called from IO_BANK0 interrupt handler.
  /// Sets bits for each button that triggered a falling edge.
  static func handle() {
    if IOBank.isInterruptPending(pinLeft, .fallingEdge) {
      IOBank.acknowledgeInterrupt(pinLeft, .fallingEdge)
      pressed |= 1
    }
    if IOBank.isInterruptPending(pinRight, .fallingEdge) {
      IOBank.acknowledgeInterrupt(pinRight, .fallingEdge)
      pressed |= 2
    }
    if IOBank.isInterruptPending(pinA, .fallingEdge) {
      IOBank.acknowledgeInterrupt(pinA, .fallingEdge)
      pressed |= 4
    }
    if IOBank.isInterruptPending(pinB, .fallingEdge) {
      IOBank.acknowledgeInterrupt(pinB, .fallingEdge)
      pressed |= 8
    }
    if IOBank.isInterruptPending(pinUp, .fallingEdge) {
      IOBank.acknowledgeInterrupt(pinUp, .fallingEdge)
      pressed |= 16
    }
    if IOBank.isInterruptPending(pinDown, .fallingEdge) {
      IOBank.acknowledgeInterrupt(pinDown, .fallingEdge)
      pressed |= 32
    }
  }

  /// Reads and clears the pressed bitmask. Call once per frame.
  static func consumePressed() -> UInt8 {
    let val = pressed
    pressed = 0
    return val
  }
}
