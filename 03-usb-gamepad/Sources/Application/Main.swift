@main
struct Application {
  static func main() {
    var board = Board()

    while true {
      let gpioState = board.buttons.poll()
      board.usb.poll()
      if board.usb.configured {
        board.usb.sendXInputReport(gpioState: gpioState)
      }

      if gpioState != 0 {
        board.led.on()
      } else {
        board.led.off()
      }
    }
  }
}
