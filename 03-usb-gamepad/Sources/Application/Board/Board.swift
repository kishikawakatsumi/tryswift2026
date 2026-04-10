/// Board-level abstraction for USB gamepad on Raspberry Pi Pico.
struct Board {
  let led = LED()
  var buttons = Buttons()
  var usb = USBDevice()

  init() {
    Clocks.initialize()
    SysTick.initialize()
    Resets.unreset(.ioBank0)
    Resets.unreset(.padsBank0)
    led.initialize()
    buttons.initialize()
    usb.initialize()
  }
}

/// On-board LED connected to GPIO25.
struct LED {
  private let pin: UInt32 = 25

  func initialize() {
    SIO.disableOutput(pin)
    SIO.clearOutput(pin)
    let padValue = PadsBank.read(pin)
    PadsBank.xor(pin, (padValue ^ 0x40) & 0xC0)  // Set IE, clear OD
    IOBank.setFunction(pin, .sio)
    SIO.enableOutput(pin)
  }

  func on() { SIO.setOutput(pin) }
  func off() { SIO.clearOutput(pin) }
}
