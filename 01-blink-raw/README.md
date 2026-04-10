# 01-blink-raw

LED blink using raw register addresses.

This is the absolute minimum bare-metal Swift program. It blinks the on-board LED (GPIO25) by writing directly to hardware register addresses.

- No global variables or static properties
- No memory initialization
- No Board abstraction
- Just raw memory-mapped I/O

![Demo](https://github.com/user-attachments/assets/f31747b0-8f59-4a07-9b5d-78130d22834b)

## What it demonstrates

- How to control hardware by writing to specific memory addresses
- The vector table and reset handler (without memory initialization)
- The minimum files needed to run Swift on bare metal
