/// Board-level abstraction for Raspberry Pi Pico.
struct Board {
  var display = Display()

  init() {
    Clocks.initialize()
    SysTick.initialize()

    // Reset all peripherals to clean state (critical for debug re-deploy)
    Resets.reset(.i2c0)
    Resets.reset(.uart0)
    Resets.reset(.pwm)
    Resets.unreset(.ioBank0)
    Resets.unreset(.padsBank0)

    UART.initialize(tx: 0, rx: 1)

    // I2C pads and function (matching reference project order)
    PadsBank.store(16, 0x4A)
    PadsBank.store(17, 0x4A)
    IOBank.setFunction(16, .i2c)
    IOBank.setFunction(17, .i2c)

    // PWM buzzer
    IOBank.setFunction(20, .pwm)

    // Button GPIOs
    initButtons()

    // GPIO interrupts for buttons (falling edge = press)
    ButtonISR.initialize()

    // OLED display
    SSD1306.portrait = true
    display.initialize()
  }

  private func configureButton(_ pin: UInt32) {
    PadsBank.store(pin, 0x4A)
    IOBank.setFunction(pin, .sio)
    SIO.disableOutput(pin)
  }

  private func initButtons() {
    configureButton(2)  // Up
    configureButton(3)  // Down
    configureButton(4)  // Left
    configureButton(5)  // Right
    configureButton(6)  // A
    configureButton(7)  // B
  }

  func print(_ message: StaticString) { UART.write(message) }
}

/// Button input (active-low with pull-ups).
enum Buttons {
  static var left: Bool { SIO.isLow(4) }
  static var right: Bool { SIO.isLow(5) }
  static var down: Bool { SIO.isLow(3) }
  static var up: Bool { SIO.isLow(2) }
  static var a: Bool { SIO.isLow(6) }
  static var b: Bool { SIO.isLow(7) }
}

/// Framebuffer display with portrait mode support.
struct Display {
  private var framebuffer = [UInt8](repeating: 0, count: SSD1306.bufferSize)

  func initialize() {
    // GPIO already configured by Board.init()
    I2C.initializeController()
    SSD1306.initialize()
    SSD1306.clear()
  }

  mutating func clear() {
    for i in 0..<framebuffer.count { framebuffer[i] = 0 }
  }

  /// Sets a pixel using logical coordinates.
  /// In portrait mode (64x128), (x,y) maps to physical (y, 63-x).
  mutating func setPixel(x: Int, y: Int) {
    var px = x
    var py = y
    if SSD1306.portrait {
      px = y
      py = 63 - x
    }
    guard px >= 0, px < SSD1306.physicalWidth,
      py >= 0, py < SSD1306.physicalHeight
    else { return }
    framebuffer[py / 8 * SSD1306.physicalWidth + px] |= UInt8(1 << (py % 8))
  }

  /// Clears a pixel using logical coordinates.
  mutating func clearPixel(x: Int, y: Int) {
    var px = x
    var py = y
    if SSD1306.portrait {
      px = y
      py = 63 - x
    }
    guard px >= 0, px < SSD1306.physicalWidth,
      py >= 0, py < SSD1306.physicalHeight
    else { return }
    framebuffer[py / 8 * SSD1306.physicalWidth + px] &= ~UInt8(1 << (py % 8))
  }

  mutating func clearRect(x: Int, y: Int, width w: Int, height h: Int) {
    for dy in 0..<h {
      for dx in 0..<w { clearPixel(x: x + dx, y: y + dy) }
    }
  }

  mutating func fillRect(x: Int, y: Int, width w: Int, height h: Int) {
    for dy in 0..<h {
      for dx in 0..<w { setPixel(x: x + dx, y: y + dy) }
    }
  }

  /// Draws a 3x5 digit at pixel position.
  mutating func drawDigit(_ digit: UInt8, x: Int, y: Int) {
    let glyph = Font3x5.digit(digit)
    for col in 0..<3 {
      var bits: UInt8 = 0
      if col == 0 { bits = glyph.0 }
      if col == 1 { bits = glyph.1 }
      if col == 2 { bits = glyph.2 }
      for row in 0..<5 {
        if bits & (1 << row) != 0 {
          setPixel(x: x + col, y: y + row)
        }
      }
    }
  }

  /// Draws a number at pixel position.
  mutating func drawScore(_ value: UInt32, x: Int, y: Int) {
    if value == 0 {
      drawDigit(0, x: x, y: y)
      return
    }
    var n = value
    var digits = 0
    while n > 0 {
      digits += 1
      n /= 10
    }
    n = value
    var dx = x + (digits - 1) * 4
    while n > 0 {
      drawDigit(UInt8(n % 10), x: dx, y: y)
      n /= 10
      dx -= 4
    }
  }

  func flush() {
    framebuffer.withUnsafeBufferPointer { SSD1306.draw($0) }
  }
}

/// Minimal 3x5 font for digits.
enum Font3x5 {
  static func digit(_ d: UInt8) -> (UInt8, UInt8, UInt8) {
    switch d {
    case 0: return (0x1F, 0x11, 0x1F)
    case 1: return (0x00, 0x1F, 0x00)
    case 2: return (0x1D, 0x15, 0x17)
    case 3: return (0x15, 0x15, 0x1F)
    case 4: return (0x07, 0x04, 0x1F)
    case 5: return (0x17, 0x15, 0x1D)
    case 6: return (0x1F, 0x15, 0x1D)
    case 7: return (0x01, 0x01, 0x1F)
    case 8: return (0x1F, 0x15, 0x1F)
    case 9: return (0x17, 0x15, 0x1F)
    default: return (0, 0, 0)
    }
  }
}
