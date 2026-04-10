# 03-usb-gamepad

USB game controller using the super loop pattern.

A leverless (all-button) fighting game controller that polls GPIO buttons and sends XInput reports to the PC over USB. The entire application runs in a simple while-true loop.

## What it demonstrates

- Super loop as the simplest execution pattern
- USB device stack implemented entirely in Swift
- GPIO button polling with software debouncing
- Why a super loop works here: every task completes instantly (just register reads/writes)

## Wiring

<img width="1158" height="2484" alt="Untitled Sketch_bb" src="https://github.com/user-attachments/assets/629ec549-783b-4c77-8f45-4bd6e2abf316" />

## Button Pin Mapping

GP2040-CE compatible pinout:

| Pin  | Button | Pin     | Button      |
| ---- | ------ | ------- | ----------- |
| GP02 | Up     | GP10    | B3          |
| GP03 | Down   | GP11    | B4          |
| GP04 | Right  | GP12    | R1          |
| GP05 | Left   | GP13    | L1          |
| GP06 | B1     | GP14    | Turbo       |
| GP07 | B2     | GP16    | S1          |
| GP08 | R2     | GP17    | S2          |
| GP09 | L2     | GP18-21 | L3/R3/A1/A2 |

All buttons are active-low with internal pull-ups enabled. GP15 is unused.
