/// RP2040 USB controller registers (base 0x5011_0000).
enum USBCtrl {
  private static let base: UInt32 = 0x5011_0000

  static let addrEndp = Register(address: base + 0x00)
  static let mainCtrl = Register(address: base + 0x40)
  static let sieCtrl = Register(address: base + 0x4C)
  static let sieStatus = Register(address: base + 0x50)
  static let buffStatus = Register(address: base + 0x58)
  static let usbMuxing = Register(address: base + 0x74)
  static let usbPwr = Register(address: base + 0x78)

  enum MainCtrlBits {
    static let controllerEn: UInt32 = 1 << 0
  }

  enum SieCtrlBits {
    static let ep0Int1Buf: UInt32 = 1 << 29
    static let pullupEn: UInt32 = 1 << 16
  }

  enum SieStatusBits {
    static let busReset: UInt32 = 1 << 19
    static let transComplete: UInt32 = 1 << 18
    static let setupRec: UInt32 = 1 << 17
    static let connected: UInt32 = 1 << 16
    static let suspended: UInt32 = 1 << 4
  }

  enum MuxingBits {
    static let toPhy: UInt32 = 1 << 0
    static let softcon: UInt32 = 1 << 3
  }

  enum PowerBits {
    static let vbusDetect: UInt32 = 1 << 2
    static let vbusDetectOverrideEn: UInt32 = 1 << 3
  }
}
