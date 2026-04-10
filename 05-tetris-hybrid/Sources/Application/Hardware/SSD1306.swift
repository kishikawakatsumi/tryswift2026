/// SSD1306 128x64 OLED display driver over I2C.
///
/// Supports portrait mode (64x128 logical) via software rotation.
/// In portrait mode, the physical OLED is rotated 90 degrees clockwise.
enum SSD1306 {
  static let physicalWidth = 128
  static let physicalHeight = 64
  static let bufferSize = physicalWidth * physicalHeight / 8  // 1024 bytes

  /// When true, coordinates are portrait (64 wide x 128 tall).
  nonisolated(unsafe) static var portrait = false

  /// Logical display dimensions.
  static var width: Int { portrait ? physicalHeight : physicalWidth }
  static var height: Int { portrait ? physicalWidth : physicalHeight }

  private static let address: UInt8 = 0x3C

  private static func sendCommand(_ cmd: UInt8) {
    I2C.writeByte(address: address, 0x00)
    I2C.continueByteWithStop(cmd)
  }

  private static func sendCommand(_ cmd: UInt8, _ arg: UInt8) {
    I2C.writeByte(address: address, 0x00)
    I2C.continueByte(cmd)
    I2C.continueByteWithStop(arg)
  }

  private static func sendCommand(_ cmd: UInt8, _ arg1: UInt8, _ arg2: UInt8) {
    I2C.writeByte(address: address, 0x00)
    I2C.continueByte(cmd)
    I2C.continueByte(arg1)
    I2C.continueByteWithStop(arg2)
  }

  static func initialize() {
    sendCommand(0xAE)
    sendCommand(0xD5, 0x80)
    sendCommand(0xA8, 0x3F)
    sendCommand(0xD3, 0x00)
    sendCommand(0x40)
    sendCommand(0x8D, 0x14)
    sendCommand(0x20, 0x00)
    sendCommand(0xA1)
    sendCommand(0xC8)
    sendCommand(0xDA, 0x12)
    sendCommand(0x81, 0xCF)  // Contrast = 207
    sendCommand(0xD9, 0xF1)
    sendCommand(0xDB, 0x40)
    sendCommand(0xA4)
    sendCommand(0xA6)
    sendCommand(0xAF)
  }

  static func draw(_ framebuffer: UnsafeBufferPointer<UInt8>) {
    sendCommand(0x21, 0x00, 0x7F)
    sendCommand(0x22, 0x00, 0x07)

    I2C.writeByte(address: address, 0x40)
    for i in 0..<framebuffer.count {
      if i == framebuffer.count - 1 {
        I2C.continueByteWithStop(framebuffer[i])
      } else {
        I2C.continueByte(framebuffer[i])
      }
    }
  }

  static func clear() {
    sendCommand(0x21, 0x00, 0x7F)
    sendCommand(0x22, 0x00, 0x07)

    I2C.writeByte(address: address, 0x40)
    for i in 0..<bufferSize {
      if i == bufferSize - 1 {
        I2C.continueByteWithStop(0x00)
      } else {
        I2C.continueByte(0x00)
      }
    }
  }
}
