@main
struct Application {
  static func main() {
    // Unreset IO_BANK0
    Register(address: 0x4000_C000).clear(1 << 5)
    while Register(address: 0x4000_C008).load() & (1 << 5) == 0 {}

    // Configure GPIO25 (on-board LED) as output
    Register(address: 0x4001_4000 + 0x04 + 25 * 8).store(5)
    Register(address: 0xD000_0024).store(1 << 25)

    // Turn on
    Register(address: 0xD000_001C).store(1 << 25)
    // Blink
    while true {
      for _ in 0..<500_000 {
        _ = Register(address: 0xD000_0000).load()
      }
      Register(address: 0xD000_001C).store(1 << 25)
    }
  }
}
