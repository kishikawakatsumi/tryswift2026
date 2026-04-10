# 04-tetris-cooperative

Tetris with a cooperative task scheduler.

Game logic, rendering, and music run as separate tasks registered with different intervals. However, since tasks cannot interrupt each other, the heavy I2C display transfer causes music to stutter.

https://github.com/user-attachments/assets/1fcbba33-8e02-42b2-8b3f-2f15a2913d86

## What it demonstrates

- Cooperative scheduler with `Scheduler.addTask(interval:handler:)`
- Task separation: game logic (16ms), rendering (16ms), music (8ms)
- The limitation of cooperative scheduling: a slow task delays all others
- Compare with [05-tetris-hybrid](../05-tetris-hybrid) to hear the difference in music playback

## Wiring

<img width="989" height="1809" alt="Untitled Sketch 2_bb" src="https://github.com/user-attachments/assets/6252cccd-801f-4102-91b8-ca5b5c5596fb" />

## Hardware

### OLED Display (SSD1306, 128x64, I2C)

| Pin  | Function |
| ---- | -------- |
| GP16 | I2C0 SDA |
| GP17 | I2C0 SCL |

### Buttons (active-low with pull-ups)

| Pin  | Button         |
| ---- | -------------- |
| GP02 | Up             |
| GP03 | Down           |
| GP04 | Left           |
| GP05 | Right          |
| GP06 | A (rotate CW)  |
| GP07 | B (rotate CCW) |

### Other

| Pin  | Function               |
| ---- | ---------------------- |
| GP00 | UART TX (debug output) |
| GP01 | UART RX                |
| GP20 | PWM buzzer (BGM)       |
| GP25 | On-board LED           |
