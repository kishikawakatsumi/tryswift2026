/// USB device state machine for XInput (Xbox 360 controller).
///
/// Handles bus reset, enumeration, endpoint configuration, and
/// sends 20-byte XInput gamepad reports on EP1 IN.
struct USBDevice {
  private var ep0DataPid: UInt32 = 0
  private var ep1DataPid: UInt32 = 0
  private var ep2OutDataPid: UInt32 = 0

  var configured: Bool = false
  var shouldSetAddress: Bool = false
  var pendingAddress: UInt8 = 0
  private var ep1Ready: Bool = false
  private var lastGpioState: UInt32 = 0xFFFF_FFFF

  mutating func initialize() {
    Resets.reset(.usbctrl)
    Resets.unreset(.usbctrl)
    USBDPRAM.clearAll()

    // Enable USB controller in device mode
    USBCtrl.mainCtrl.store(USBCtrl.MainCtrlBits.controllerEn)

    // Route USB to internal PHY with soft connect
    USBCtrl.usbMuxing.store(
      USBCtrl.MuxingBits.toPhy | USBCtrl.MuxingBits.softcon)

    // Force VBUS detect (board has no VBUS sense pin)
    USBCtrl.usbPwr.store(
      USBCtrl.PowerBits.vbusDetect | USBCtrl.PowerBits.vbusDetectOverrideEn)

    // Configure EP0 for single-buffered operation
    USBCtrl.sieCtrl.store(USBCtrl.SieCtrlBits.ep0Int1Buf)

    // Start at address 0 (before enumeration)
    USBCtrl.addrEndp.store(0)

    // Enable pull-up to signal device presence to host
    USBCtrl.sieCtrl.set(USBCtrl.SieCtrlBits.pullupEn)
  }

  mutating func poll() {
    let status = USBCtrl.sieStatus.load()

    // Handle bus reset (host resets device)
    if (status & USBCtrl.SieStatusBits.busReset) != 0 {
      handleBusReset()
    }
    // Handle setup packet received
    if (status & USBCtrl.SieStatusBits.setupRec) != 0 {
      handleSetupPacket()
    }

    // Handle endpoint buffer completions
    let buffStatus = USBCtrl.buffStatus.load()

    // EP0 IN complete (bit 0)
    if (buffStatus & 0x01) != 0 {
      USBCtrl.buffStatus.store(0x01)  // W1C
      handleEP0InComplete()
    }
    // EP0 OUT complete (bit 1)
    if (buffStatus & 0x02) != 0 {
      USBCtrl.buffStatus.store(0x02)  // W1C
    }
    // EP1 IN complete (bit 2)
    if (buffStatus & 0x04) != 0 {
      USBCtrl.buffStatus.store(0x04)  // W1C
      ep1Ready = true
    }
    // EP2 OUT complete (bit 5)
    if (buffStatus & 0x20) != 0 {
      USBCtrl.buffStatus.store(0x20)  // W1C
      prepareEP2Out()
    }
  }

  // MARK: - Bus reset

  private mutating func handleBusReset() {
    // Clear bus reset flag (W1C)
    USBCtrl.sieStatus.store(USBCtrl.SieStatusBits.busReset)
    USBCtrl.addrEndp.store(0)
    configured = false
    shouldSetAddress = false
    ep0DataPid = 0
    ep1DataPid = 0
    ep2OutDataPid = 0
    ep1Ready = false
    lastGpioState = 0xFFFF_FFFF
  }

  // MARK: - Setup packet handling

  private mutating func handleSetupPacket() {
    // Clear setup received flag (W1C)
    USBCtrl.sieStatus.store(USBCtrl.SieStatusBits.setupRec)
    let pkt = SetupPacket()
    ep0DataPid = 1
    USBSetupHandler.handleSetup(pkt, device: &self)
  }

  // MARK: - EP0 completion

  private mutating func handleEP0InComplete() {
    if shouldSetAddress {
      USBCtrl.addrEndp.store(UInt32(pendingAddress))
      shouldSetAddress = false
    } else {
      // Prepare EP0 OUT for status stage (zero-length DATA1)
      let ctrl: UInt32 = USBDPRAM.BufCtrl.dataPid
      USBDPRAM.store(USBDPRAM.ep0OutBufCtrl, ctrl)
      busyWait12Cycles()
      USBDPRAM.store(USBDPRAM.ep0OutBufCtrl, ctrl | USBDPRAM.BufCtrl.available)
    }
  }

  // MARK: - EP0 control transfers

  mutating func sendEP0In(length: UInt32) {
    var ctrl = length & USBDPRAM.BufCtrl.lengthMask
    ctrl |= USBDPRAM.BufCtrl.full
    ctrl |= USBDPRAM.BufCtrl.last
    if ep0DataPid != 0 { ctrl |= USBDPRAM.BufCtrl.dataPid }
    ep0DataPid ^= 1
    USBDPRAM.store(USBDPRAM.ep0InBufCtrl, ctrl)
    busyWait12Cycles()
    USBDPRAM.store(USBDPRAM.ep0InBufCtrl, ctrl | USBDPRAM.BufCtrl.available)
  }

  func stallEP0() {
    USBDPRAM.store(USBDPRAM.ep0InBufCtrl, USBDPRAM.BufCtrl.stall)
    USBDPRAM.store(USBDPRAM.ep0OutBufCtrl, USBDPRAM.BufCtrl.stall)
  }

  // MARK: - Data endpoint configuration

  mutating func configureEndpoints() {
    // EP1 IN: Interrupt endpoint for gamepad reports
    let ep1Ctrl =
      USBDPRAM.EpCtrl.enable
      | USBDPRAM.EpCtrl.interruptPerBuff
      | USBDPRAM.EpCtrl.typeInterrupt
      | USBDPRAM.EpCtrl.bufferAddress(USBDPRAM.ep1InBuf)
    USBDPRAM.store(USBDPRAM.epInControl(1), ep1Ctrl)
    ep1DataPid = 0
    ep1Ready = true

    // EP2 OUT: Interrupt endpoint for force feedback (ignored)
    let ep2Ctrl =
      USBDPRAM.EpCtrl.enable
      | USBDPRAM.EpCtrl.interruptPerBuff
      | USBDPRAM.EpCtrl.typeInterrupt
      | USBDPRAM.EpCtrl.bufferAddress(USBDPRAM.ep2OutBuf)
    USBDPRAM.store(USBDPRAM.epOutControl(2), ep2Ctrl)
    ep2OutDataPid = 0
    prepareEP2Out()
  }

  private mutating func prepareEP2Out() {
    var ctrl: UInt32 = 32  // Max packet size
    if ep2OutDataPid != 0 { ctrl |= USBDPRAM.BufCtrl.dataPid }
    ep2OutDataPid ^= 1
    USBDPRAM.store(USBDPRAM.epOutBufCtrl(2), ctrl)
    busyWait12Cycles()
    USBDPRAM.store(USBDPRAM.epOutBufCtrl(2), ctrl | USBDPRAM.BufCtrl.available)
  }

  // MARK: - XInput report

  /// Sends a 20-byte XInput gamepad report when button state changes.
  ///
  /// GP2040-CE default Pico pin mapping:
  ///   GP02=Up  GP03=Down  GP04=Right  GP05=Left
  ///   GP06=B1  GP07=B2    GP08=R2     GP09=L2
  ///   GP10=B3  GP11=B4    GP12=R1     GP13=L1
  ///   GP16=S1  GP17=S2    GP18=L3     GP19=R3
  ///   GP20=A1
  mutating func sendXInputReport(gpioState: UInt32) {
    if !configured || !ep1Ready { return }
    if gpioState == lastGpioState { return }
    lastGpioState = gpioState

    let buf = USBDPRAM.ep1InBuf

    // Header
    USBDPRAM.storeByte(buf + 0, 0x00)  // Message type
    USBDPRAM.storeByte(buf + 1, 0x14)  // Report length (20)

    // Byte 2: D-pad + Start/Back/L3/R3
    var b2: UInt8 = 0
    if (gpioState >> 2) & 1 != 0 { b2 |= 0x01 }  // Up
    if (gpioState >> 3) & 1 != 0 { b2 |= 0x02 }  // Down
    if (gpioState >> 5) & 1 != 0 { b2 |= 0x04 }  // Left
    if (gpioState >> 4) & 1 != 0 { b2 |= 0x08 }  // Right
    if (gpioState >> 17) & 1 != 0 { b2 |= 0x10 }  // Start (S2)
    if (gpioState >> 16) & 1 != 0 { b2 |= 0x20 }  // Back (S1)
    if (gpioState >> 18) & 1 != 0 { b2 |= 0x40 }  // L3
    if (gpioState >> 19) & 1 != 0 { b2 |= 0x80 }  // R3
    USBDPRAM.storeByte(buf + 2, b2)

    // Byte 3: LB/RB/Guide/A/B/X/Y
    var b3: UInt8 = 0
    if (gpioState >> 13) & 1 != 0 { b3 |= 0x01 }  // LB (L1)
    if (gpioState >> 12) & 1 != 0 { b3 |= 0x02 }  // RB (R1)
    if (gpioState >> 20) & 1 != 0 { b3 |= 0x04 }  // Guide (A1)
    if (gpioState >> 6) & 1 != 0 { b3 |= 0x10 }  // A (B1)
    if (gpioState >> 7) & 1 != 0 { b3 |= 0x20 }  // B (B2)
    if (gpioState >> 10) & 1 != 0 { b3 |= 0x40 }  // X (B3)
    if (gpioState >> 11) & 1 != 0 { b3 |= 0x80 }  // Y (B4)
    USBDPRAM.storeByte(buf + 3, b3)

    // Bytes 4-5: Analog triggers (digital: 0x00 or 0xFF)
    let lt: UInt8 = ((gpioState >> 9) & 1 != 0) ? 0xFF : 0x00  // LT (L2)
    let rt: UInt8 = ((gpioState >> 8) & 1 != 0) ? 0xFF : 0x00  // RT (R2)
    USBDPRAM.storeByte(buf + 4, lt)
    USBDPRAM.storeByte(buf + 5, rt)

    // Bytes 6-19: Analog sticks (unused, zero)
    var i: UInt32 = 6
    while i < 20 {
      USBDPRAM.storeByte(buf + i, 0x00)
      i &+= 1
    }

    // Submit EP1 IN buffer
    var ctrl: UInt32 = 20  // 20-byte report
    ctrl |= USBDPRAM.BufCtrl.full
    ctrl |= USBDPRAM.BufCtrl.last
    if ep1DataPid != 0 { ctrl |= USBDPRAM.BufCtrl.dataPid }
    ep1DataPid ^= 1
    USBDPRAM.store(USBDPRAM.epInBufCtrl(1), ctrl)
    busyWait12Cycles()
    USBDPRAM.store(USBDPRAM.epInBufCtrl(1), ctrl | USBDPRAM.BufCtrl.available)
    ep1Ready = false
  }

  // MARK: - Timing

  /// RP2040 USB requires ~12 cycles between buffer control writes.
  private func busyWait12Cycles() {
    _ = USBCtrl.sieStatus.load()
    _ = USBCtrl.sieStatus.load()
    _ = USBCtrl.sieStatus.load()
    _ = USBCtrl.sieStatus.load()
    _ = USBCtrl.sieStatus.load()
    _ = USBCtrl.sieStatus.load()
  }
}
