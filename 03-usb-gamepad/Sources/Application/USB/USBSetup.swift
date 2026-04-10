/// Parses an 8-byte USB setup packet from DPRAM.
struct SetupPacket {
  let bmRequestType: UInt8
  let bRequest: UInt8
  let wValue: UInt16
  let wIndex: UInt16
  let wLength: UInt16

  init() {
    let low = USBDPRAM.load(USBDPRAM.setupPacketLow)
    let high = USBDPRAM.load(USBDPRAM.setupPacketHigh)
    bmRequestType = UInt8(low & 0xFF)
    bRequest = UInt8((low >> 8) & 0xFF)
    wValue = UInt16((low >> 16) & 0xFFFF)
    wIndex = UInt16(high & 0xFFFF)
    wLength = UInt16((high >> 16) & 0xFFFF)
  }

  var descriptorType: UInt8 { UInt8(wValue >> 8) }
  var descriptorIndex: UInt8 { UInt8(wValue & 0xFF) }
}

/// Handles USB control (EP0) setup requests.
enum USBSetupHandler {
  private enum Request {
    static let getStatus: UInt8 = 0
    static let setAddress: UInt8 = 5
    static let getDescriptor: UInt8 = 6
    static let setConfiguration: UInt8 = 9
    static let setInterface: UInt8 = 11
  }

  private enum DescriptorType {
    static let device: UInt8 = 1
    static let configuration: UInt8 = 2
    static let string: UInt8 = 3
  }

  static func handleSetup(_ pkt: SetupPacket, device: inout USBDevice) {
    // XInput: only handle standard requests. STALL vendor/class requests.
    let reqType = (pkt.bmRequestType >> 5) & 0x03
    if reqType != 0 {
      device.stallEP0()
      return
    }

    switch pkt.bRequest {
    case Request.getDescriptor:
      handleGetDescriptor(pkt, device: &device)
    case Request.setAddress:
      device.pendingAddress = UInt8(pkt.wValue & 0x7F)
      device.shouldSetAddress = true
      device.sendEP0In(length: 0)
    case Request.setConfiguration:
      device.configured = true
      device.configureEndpoints()
      device.sendEP0In(length: 0)
    case Request.getStatus:
      USBDPRAM.storeByte(USBDPRAM.ep0Buf, 0)
      USBDPRAM.storeByte(USBDPRAM.ep0Buf + 1, 0)
      device.sendEP0In(length: 2)
    case Request.setInterface:
      device.sendEP0In(length: 0)
    default:
      device.stallEP0()
    }
  }

  private static func handleGetDescriptor(
    _ pkt: SetupPacket, device: inout USBDevice
  ) {
    var length: UInt32 = 0

    switch pkt.descriptorType {
    case DescriptorType.device:
      length = USBDescriptors.writeDevice(to: 0)
    case DescriptorType.configuration:
      length = USBDescriptors.writeConfiguration(to: 0)
    case DescriptorType.string:
      switch pkt.descriptorIndex {
      case 0:
        length = USBDescriptors.writeStringLangID(to: 0)
      case 1:
        length = USBDescriptors.writeStringManufacturer(to: 0)
      case 2:
        length = USBDescriptors.writeStringProduct(to: 0)
      case 3:
        length = USBDescriptors.writeStringSerial(to: 0)
      default:
        device.stallEP0()
        return
      }
    default:
      // Device Qualifier (6) etc. -> STALL (Full Speed only device)
      device.stallEP0()
      return
    }

    let sendLength = min(length, UInt32(pkt.wLength))
    device.sendEP0In(length: sendLength)
  }
}
