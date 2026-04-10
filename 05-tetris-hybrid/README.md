# 05-tetris-hybrid

Tetris with a hybrid scheduler combining cooperative tasks and hardware interrupts.

Game logic and rendering run as cooperative scheduler tasks, while music and button input are handled by hardware interrupts. This ensures smooth music playback and instant button response even during heavy I2C display transfers.

## What it demonstrates

- Hybrid scheduling: cooperative tasks + hardware interrupts
- SysTick interrupt for precise music timing (1ms resolution)
- GPIO interrupt for instant button input capture
- The vector table connecting interrupt handlers to hardware
- Compare with [04-tetris-cooperative](../04-tetris-cooperative) to hear the difference

## Wiring

<img width="989" height="1809" alt="Untitled Sketch 2_bb" src="https://github.com/user-attachments/assets/6252cccd-801f-4102-91b8-ca5b5c5596fb" />

## Hardware

### OLED Display (SSD1306, 128x64, I2C)

| Pin  | Function |
| ---- | -------- |
| GP16 | I2C0 SDA |
| GP17 | I2C0 SCL |

### Buttons (active-low with pull-ups, interrupt-driven)

| Pin  | Button         | Interrupt         |
| ---- | -------------- | ----------------- |
| GP02 | Up             | GPIO falling edge |
| GP03 | Down           | GPIO falling edge |
| GP04 | Left           | GPIO falling edge |
| GP05 | Right          | GPIO falling edge |
| GP06 | A (rotate CW)  | GPIO falling edge |
| GP07 | B (rotate CCW) | GPIO falling edge |

### Other

| Pin  | Function                                      |
| ---- | --------------------------------------------- |
| GP00 | UART TX (debug output)                        |
| GP01 | UART RX                                       |
| GP20 | PWM buzzer (BGM, driven by SysTick interrupt) |
| GP25 | On-board LED                                  |
