# Writing Swift Without an OS

Sample code for the try! Swift 2026 talk "Writing Swift Without an OS."

- [Video](https://youtu.be/vDQ_yxD6JZ4?si=qL1fuG_3haHOtbdy)
- [Slides](https://speakerdeck.com/kishikawakatsumi/running-swift-without-an-os)
- [Slides with speaker notes (Keynote)](https://www.icloud.com/keynote/013G6WIHGoKbPIk06gcljQ0jA#Bare_Metal_Swift)

Bare-metal Raspberry Pi Pico examples in 100% Swift. No C code, no Pico SDK, no OS.

For more progressive examples (from boot to OLED display, button input, and more), see [pico-bare-swift](https://github.com/kishikawakatsumi/pico-bare-swift).

## Examples

| Example | Description |
|---------|-------------|
| [01-blink-raw](01-blink-raw) | LED blink using raw register addresses. No global variables, no memory initialization. The absolute minimum. |
| [02-blink-constants](02-blink-constants) | LED blink with named constants. Adds memory initialization so global variables and static properties work. |
| [03-usb-gamepad](03-usb-gamepad) | USB game controller (super loop). Polls buttons and sends XInput reports to PC. |
| [04-tetris-cooperative](04-tetris-cooperative) | Tetris with cooperative scheduler. Tasks run at different intervals, but cannot interrupt each other. |
| [05-tetris-hybrid](05-tetris-hybrid) | Tetris with hybrid scheduler. Music and button input run as hardware interrupts for precise timing. |

## Requirements

- **Swift 6.3** or later from [swift.org](https://www.swift.org/install/) (the Xcode-bundled toolchain does not include the ARM cross-compilation target required for Embedded Swift)

Install with [swiftly](https://github.com/swiftlang/swiftly):

```
swiftly install 6.3
```

## Build

```
cd 01-blink-raw
make release
```

Or directly with `swift build`:

```
swift build --triple armv6m-none-none-eabi -c release --toolset toolset.json
```

The output ELF is at `.build/armv6m-none-none-eabi/release/Application`. Running `make` or `make release` also generates `.build/firmware.uf2`.

## Flash

Hold the **BOOTSEL** button on the Pico while plugging it into USB. It appears as a USB drive. Copy the UF2 file:

```
cp .build/firmware.uf2 /Volumes/RPI-RP2/
```

## Hardware

These examples are designed for the **Raspberry Pi Pico** (RP2040).

- **01, 02**: No extra wiring needed. Uses the on-board LED (GPIO25).
- **03**: 6 buttons connected to GPIO pins (GP2040-CE compatible pinout).
- **04, 05**: 128x64 OLED display (SSD1306, I2C), 6 buttons, piezo buzzer (PWM).

## Project Structure

Each example follows the same layout:

```
Sources/Application/
  Main.swift              # Application entry point
  Board/
    Board.swift           # Board and peripheral abstraction
  Hardware/
    MMIO.swift            # Register type for volatile hardware access
    GPIO.swift            # SIO, IOBank, PadsBank
    Resets.swift          # Peripheral reset controller
    ...                   # Additional peripherals per example
  Kernel/                 # (04, 05 only)
    Scheduler.swift       # Cooperative task scheduler
  Support/
    Boot2.swift           # RP2040 second stage bootloader binary
    VectorTable.swift     # ARM Cortex-M0+ vector table and handlers
    Startup.swift         # Memory section initialization
    RuntimeStubs.swift    # Heap allocator, atomics, memcpy/memset
```

## License

This project is licensed under the [MIT License](LICENSE).

The boot2 binary is derived from the [Raspberry Pi Pico SDK](https://github.com/raspberrypi/pico-sdk) and is licensed under the BSD 3-Clause License.
