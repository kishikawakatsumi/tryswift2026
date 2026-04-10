/// Xbox 360 Controller USB Descriptors.
/// XInput uses Vendor-specific class (0xFF), not standard HID.
enum USBDescriptors {
  // Device Descriptor (18 bytes) - Xbox 360 Controller
  static func writeDevice(to bufferOffset: UInt32) -> UInt32 {
    let buf = USBDPRAM.ep0Buf + bufferOffset
    USBDPRAM.storeByte(buf + 0, 18)  // bLength
    USBDPRAM.storeByte(buf + 1, 1)  // bDescriptorType = DEVICE
    USBDPRAM.storeByte(buf + 2, 0x00)  // bcdUSB low = 2.00
    USBDPRAM.storeByte(buf + 3, 0x02)  // bcdUSB high
    USBDPRAM.storeByte(buf + 4, 0xFF)  // bDeviceClass = Vendor Specific
    USBDPRAM.storeByte(buf + 5, 0xFF)  // bDeviceSubClass
    USBDPRAM.storeByte(buf + 6, 0xFF)  // bDeviceProtocol
    USBDPRAM.storeByte(buf + 7, 64)  // bMaxPacketSize0
    USBDPRAM.storeByte(buf + 8, 0x5E)  // idVendor low = 0x045E (Microsoft)
    USBDPRAM.storeByte(buf + 9, 0x04)  // idVendor high
    USBDPRAM.storeByte(buf + 10, 0x8E)  // idProduct low = 0x028E (Xbox 360)
    USBDPRAM.storeByte(buf + 11, 0x02)  // idProduct high
    USBDPRAM.storeByte(buf + 12, 0x14)  // bcdDevice low = 1.14
    USBDPRAM.storeByte(buf + 13, 0x01)  // bcdDevice high
    USBDPRAM.storeByte(buf + 14, 1)  // iManufacturer = string #1
    USBDPRAM.storeByte(buf + 15, 2)  // iProduct = string #2
    USBDPRAM.storeByte(buf + 16, 3)  // iSerialNumber = string #3
    USBDPRAM.storeByte(buf + 17, 1)  // bNumConfigurations
    return 18
  }

  // Configuration Descriptor (48 bytes total)
  // Config(9) + Interface(9) + Xbox Vendor(16) + EP1 IN(7) + EP2 OUT(7)
  static func writeConfiguration(to bufferOffset: UInt32) -> UInt32 {
    let buf = USBDPRAM.ep0Buf + bufferOffset

    // Configuration descriptor (9 bytes)
    USBDPRAM.storeByte(buf + 0, 9)  // bLength
    USBDPRAM.storeByte(buf + 1, 2)  // bDescriptorType = CONFIGURATION
    USBDPRAM.storeByte(buf + 2, 48)  // wTotalLength low
    USBDPRAM.storeByte(buf + 3, 0)  // wTotalLength high
    USBDPRAM.storeByte(buf + 4, 1)  // bNumInterfaces
    USBDPRAM.storeByte(buf + 5, 1)  // bConfigurationValue
    USBDPRAM.storeByte(buf + 6, 0)  // iConfiguration
    USBDPRAM.storeByte(buf + 7, 0x80)  // bmAttributes = bus powered
    USBDPRAM.storeByte(buf + 8, 0xFA)  // bMaxPower = 500mA

    // Interface descriptor (9 bytes)
    USBDPRAM.storeByte(buf + 9, 9)  // bLength
    USBDPRAM.storeByte(buf + 10, 4)  // bDescriptorType = INTERFACE
    USBDPRAM.storeByte(buf + 11, 0)  // bInterfaceNumber
    USBDPRAM.storeByte(buf + 12, 0)  // bAlternateSetting
    USBDPRAM.storeByte(buf + 13, 2)  // bNumEndpoints = 2 (IN + OUT)
    USBDPRAM.storeByte(buf + 14, 0xFF)  // bInterfaceClass = Vendor Specific
    USBDPRAM.storeByte(buf + 15, 0x5D)  // bInterfaceSubClass = XInput
    USBDPRAM.storeByte(buf + 16, 0x01)  // bInterfaceProtocol = Gamepad
    USBDPRAM.storeByte(buf + 17, 0)  // iInterface

    // Xbox 360 vendor descriptor (16 bytes) - required for XInput recognition
    USBDPRAM.storeByte(buf + 18, 0x10)  // bLength = 16
    USBDPRAM.storeByte(buf + 19, 0x21)  // bDescriptorType = 0x21 (vendor)
    USBDPRAM.storeByte(buf + 20, 0x10)
    USBDPRAM.storeByte(buf + 21, 0x01)
    USBDPRAM.storeByte(buf + 22, 0x01)
    USBDPRAM.storeByte(buf + 23, 0x25)
    USBDPRAM.storeByte(buf + 24, 0x81)  // EP1 IN address
    USBDPRAM.storeByte(buf + 25, 0x14)  // Max input report = 20 bytes
    USBDPRAM.storeByte(buf + 26, 0x00)
    USBDPRAM.storeByte(buf + 27, 0x00)
    USBDPRAM.storeByte(buf + 28, 0x00)
    USBDPRAM.storeByte(buf + 29, 0x00)
    USBDPRAM.storeByte(buf + 30, 0x13)
    USBDPRAM.storeByte(buf + 31, 0x02)  // EP2 OUT address
    USBDPRAM.storeByte(buf + 32, 0x08)  // Max output report = 8 bytes
    USBDPRAM.storeByte(buf + 33, 0x00)

    // EP1 IN descriptor (7 bytes) - Interrupt, 32 bytes, 1ms
    USBDPRAM.storeByte(buf + 34, 7)  // bLength
    USBDPRAM.storeByte(buf + 35, 5)  // bDescriptorType = ENDPOINT
    USBDPRAM.storeByte(buf + 36, 0x81)  // bEndpointAddress = EP1 IN
    USBDPRAM.storeByte(buf + 37, 0x03)  // bmAttributes = Interrupt
    USBDPRAM.storeByte(buf + 38, 0x20)  // wMaxPacketSize = 32 low
    USBDPRAM.storeByte(buf + 39, 0x00)  // wMaxPacketSize high
    USBDPRAM.storeByte(buf + 40, 1)  // bInterval = 1ms

    // EP2 OUT descriptor (7 bytes) - Interrupt, 32 bytes, 8ms
    USBDPRAM.storeByte(buf + 41, 7)  // bLength
    USBDPRAM.storeByte(buf + 42, 5)  // bDescriptorType = ENDPOINT
    USBDPRAM.storeByte(buf + 43, 0x02)  // bEndpointAddress = EP2 OUT
    USBDPRAM.storeByte(buf + 44, 0x03)  // bmAttributes = Interrupt
    USBDPRAM.storeByte(buf + 45, 0x20)  // wMaxPacketSize = 32 low
    USBDPRAM.storeByte(buf + 46, 0x00)  // wMaxPacketSize high
    USBDPRAM.storeByte(buf + 47, 8)  // bInterval = 8ms

    return 48
  }

  // String Descriptor #0: Language ID
  static func writeStringLangID(to bufferOffset: UInt32) -> UInt32 {
    let buf = USBDPRAM.ep0Buf + bufferOffset
    USBDPRAM.storeByte(buf + 0, 4)
    USBDPRAM.storeByte(buf + 1, 3)
    USBDPRAM.storeByte(buf + 2, 0x09)
    USBDPRAM.storeByte(buf + 3, 0x04)
    return 4
  }

  // String Descriptor #1: Manufacturer
  static func writeStringManufacturer(to bufferOffset: UInt32) -> UInt32 {
    let buf = USBDPRAM.ep0Buf + bufferOffset
    let len: UInt32 = 2 + 5 * 2  // "Swift" = 12 bytes
    USBDPRAM.storeByte(buf + 0, UInt8(len))
    USBDPRAM.storeByte(buf + 1, 3)
    writeUTF16Char(buf + 2, 0x53)  // S
    writeUTF16Char(buf + 4, 0x77)  // w
    writeUTF16Char(buf + 6, 0x69)  // i
    writeUTF16Char(buf + 8, 0x66)  // f
    writeUTF16Char(buf + 10, 0x74)  // t
    return len
  }

  // String Descriptor #2: Product
  static func writeStringProduct(to bufferOffset: UInt32) -> UInt32 {
    let buf = USBDPRAM.ep0Buf + bufferOffset
    let len: UInt32 = 2 + 10 * 2  // "Controller" = 22 bytes
    USBDPRAM.storeByte(buf + 0, UInt8(len))
    USBDPRAM.storeByte(buf + 1, 3)
    writeUTF16Char(buf + 2, 0x43)  // C
    writeUTF16Char(buf + 4, 0x6F)  // o
    writeUTF16Char(buf + 6, 0x6E)  // n
    writeUTF16Char(buf + 8, 0x74)  // t
    writeUTF16Char(buf + 10, 0x72)  // r
    writeUTF16Char(buf + 12, 0x6F)  // o
    writeUTF16Char(buf + 14, 0x6C)  // l
    writeUTF16Char(buf + 16, 0x6C)  // l
    writeUTF16Char(buf + 18, 0x65)  // e
    writeUTF16Char(buf + 20, 0x72)  // r
    return len
  }

  // String Descriptor #3: Serial Number
  static func writeStringSerial(to bufferOffset: UInt32) -> UInt32 {
    let buf = USBDPRAM.ep0Buf + bufferOffset
    let len: UInt32 = 2 + 1 * 2  // "1" = 4 bytes
    USBDPRAM.storeByte(buf + 0, UInt8(len))
    USBDPRAM.storeByte(buf + 1, 3)
    writeUTF16Char(buf + 2, 0x31)  // 1
    return len
  }

  private static func writeUTF16Char(_ offset: UInt32, _ char: UInt16) {
    USBDPRAM.storeByte(offset, UInt8(char & 0xFF))
    USBDPRAM.storeByte(offset + 1, UInt8(char >> 8))
  }
}
