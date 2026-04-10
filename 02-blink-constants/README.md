# 02-blink-constants

LED blink with named constants instead of magic numbers.

Builds on 01-blink-raw by replacing raw register addresses with named constants using global variables and static properties. This requires memory initialization before main() to copy initial values from ROM to RAM.

![Demo](https://github.com/user-attachments/assets/f31747b0-8f59-4a07-9b5d-78130d22834b)

## What it demonstrates

- Memory section initialization (.data copy, .bss zeroing)
- Why global variables need explicit initialization on bare metal
- The reset handler calling `initializeMemorySections()` before `main()`
- Board abstraction with type-safe register access
