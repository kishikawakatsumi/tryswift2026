import _Volatile

/// USB dual-port RAM (4 KB at 0x5010_0000).
///
/// Contains setup packet data, endpoint control/buffer registers,
/// and data buffers. Only supports 32-bit aligned access.
enum USBDPRAM {
  static let base: UInt32 = 0x5010_0000

  // Setup packet
  static let setupPacketLow: UInt32 = 0x00
  static let setupPacketHigh: UInt32 = 0x04

  // EP1-15 IN/OUT control (EP1_IN=0x08, EP1_OUT=0x0C, EP2_IN=0x10, ...)
  static func epInControl(_ ep: UInt32) -> UInt32 { 0x08 + (ep - 1) &* 8 }
  static func epOutControl(_ ep: UInt32) -> UInt32 { 0x0C + (ep - 1) &* 8 }

  // Buffer control (EP0_IN=0x80, EP0_OUT=0x84, EP1_IN=0x88, ...)
  static let ep0InBufCtrl: UInt32 = 0x80
  static let ep0OutBufCtrl: UInt32 = 0x84
  static func epInBufCtrl(_ ep: UInt32) -> UInt32 { 0x80 + ep &* 8 }
  static func epOutBufCtrl(_ ep: UInt32) -> UInt32 { 0x84 + ep &* 8 }

  // Buffer data offsets
  static let ep0Buf: UInt32 = 0x100  // 64 bytes
  static let ep1InBuf: UInt32 = 0x140  // 64 bytes
  static let ep2OutBuf: UInt32 = 0x180  // 64 bytes

  // Buffer control bits
  enum BufCtrl {
    static let full: UInt32 = 1 << 15
    static let last: UInt32 = 1 << 14
    static let dataPid: UInt32 = 1 << 13  // 0=DATA0, 1=DATA1
    static let stall: UInt32 = 1 << 11
    static let available: UInt32 = 1 << 10
    static let lengthMask: UInt32 = 0x3FF
  }

  // Endpoint control bits
  enum EpCtrl {
    static let enable: UInt32 = 1 << 31
    static let interruptPerBuff: UInt32 = 1 << 29
    static let typeInterrupt: UInt32 = 3 << 26
    static func bufferAddress(_ addr: UInt32) -> UInt32 { addr & 0xFFFF }
  }

  // MARK: - Memory access

  @inline(__always)
  static func load(_ offset: UInt32) -> UInt32 {
    VolatileMappedRegister<UInt32>(unsafeBitPattern: UInt(base + offset)).load()
  }

  @inline(__always)
  static func store(_ offset: UInt32, _ value: UInt32) {
    VolatileMappedRegister<UInt32>(unsafeBitPattern: UInt(base + offset)).store(value)
  }

  /// Writes a single byte within the 32-bit aligned DPRAM.
  static func storeByte(_ offset: UInt32, _ value: UInt8) {
    let wordOffset = offset & ~0x3
    let bytePos = offset & 0x3
    var word = load(wordOffset)
    word &= ~(0xFF << (bytePos &* 8))
    word |= UInt32(value) << (bytePos &* 8)
    store(wordOffset, word)
  }

  /// Zeros the entire 4 KB DPRAM.
  static func clearAll() {
    var offset: UInt32 = 0
    while offset < 4096 {
      store(offset, 0)
      offset &+= 4
    }
  }
}
