nonisolated(unsafe) var board = Board()

// Game state: 0=title, 1=playing, 2=gameover
nonisolated(unsafe) var gameState: UInt8 = 0

// Timing
nonisolated(unsafe) var lastFallMs: UInt32 = 0
nonisolated(unsafe) var lastInputMs: UInt32 = 0
nonisolated(unsafe) var lastDownMs: UInt32 = 0
nonisolated(unsafe) var lastButtons: UInt8 = 0
nonisolated(unsafe) var frameCount: UInt32 = 0

let cellSize = 6
let boardLeft = 2
let boardTop = 8

// MARK: - Task Handlers

/// Music task: advance BGM every 8ms.
/// In the cooperative scheduler, this task cannot interrupt other tasks.
/// If taskRender() takes too long, music will stutter.
@c
func taskMusic() {
  Music.advance()
}

/// Input + game logic task: poll buttons and update game state every 16ms.
@c
func taskGameUpdate() {
  let now = SysTick.milliseconds
  frameCount &+= 1

  if gameState == 0 {
    titleUpdate()
  } else if gameState == 1 {
    handleInput(now)
    if now &- lastFallMs >= Tetris.fallInterval {
      lastFallMs = now
      if !Tetris.moveDown() { Tetris.lockAndSpawn() }
    }
    if Tetris.gameOver {
      Music.stop()
      gameState = 2
      lastButtons = 0xFF
      frameCount = 0
    }
  } else {
    gameOverUpdate()
  }
}

/// Render task: draw to OLED display every 16ms.
/// This is the heaviest task (I2C transfer ~25ms).
/// While this runs, no other task can execute.
@c
func taskRender() {
  if gameState == 0 {
    renderTitle()
  } else if gameState == 1 {
    renderGame()
  } else {
    renderGameOver()
  }
  board.display.flush()
}

// MARK: - Entry Point

@main
struct Application {
  static func main() {
    board.print("Tetris (Cooperative Scheduler) starting...\r\n")
    Music.initialize()
    gameState = 0

    Scheduler.addTask(interval: 8, taskMusic)
    Scheduler.addTask(interval: 16, taskGameUpdate)
    Scheduler.addTask(interval: 16, taskRender)
    Scheduler.run()
  }
}

// MARK: - Title

func titleUpdate() {
  if Buttons.a || Buttons.b {
    Tetris.initialize()
    Music.initialize()
    lastFallMs = SysTick.milliseconds
    lastButtons = 0xFF
    gameState = 1
  }
}

func renderTitle() {
  board.display.clear()

  // "TETRIS" drawn with small blocks
  // T
  board.display.fillRect(x: 4, y: 20, width: 9, height: 2)
  board.display.fillRect(x: 7, y: 22, width: 3, height: 8)
  // E
  board.display.fillRect(x: 15, y: 20, width: 7, height: 2)
  board.display.fillRect(x: 15, y: 20, width: 3, height: 10)
  board.display.fillRect(x: 15, y: 25, width: 5, height: 2)
  board.display.fillRect(x: 15, y: 28, width: 7, height: 2)
  // T
  board.display.fillRect(x: 24, y: 20, width: 9, height: 2)
  board.display.fillRect(x: 27, y: 22, width: 3, height: 8)
  // R
  board.display.fillRect(x: 35, y: 20, width: 3, height: 10)
  board.display.fillRect(x: 35, y: 20, width: 7, height: 2)
  board.display.fillRect(x: 40, y: 22, width: 2, height: 3)
  board.display.fillRect(x: 35, y: 25, width: 7, height: 2)
  board.display.fillRect(x: 40, y: 27, width: 2, height: 3)
  // I
  board.display.fillRect(x: 45, y: 20, width: 3, height: 10)
  // S
  board.display.fillRect(x: 50, y: 20, width: 7, height: 2)
  board.display.fillRect(x: 50, y: 22, width: 3, height: 3)
  board.display.fillRect(x: 50, y: 25, width: 7, height: 2)
  board.display.fillRect(x: 54, y: 27, width: 3, height: 1)
  board.display.fillRect(x: 50, y: 28, width: 7, height: 2)

  // Blinking "PRESS A"
  if frameCount / 10 % 2 == 0 {
    board.display.fillRect(x: 12, y: 80, width: 2, height: 5)
    board.display.fillRect(x: 14, y: 80, width: 2, height: 1)
    board.display.fillRect(x: 15, y: 81, width: 1, height: 1)
    board.display.fillRect(x: 14, y: 82, width: 2, height: 1)
    board.display.fillRect(x: 19, y: 80, width: 2, height: 5)
    board.display.fillRect(x: 21, y: 80, width: 2, height: 1)
    board.display.fillRect(x: 21, y: 82, width: 2, height: 1)
    board.display.fillRect(x: 22, y: 83, width: 1, height: 2)
    board.display.fillRect(x: 26, y: 80, width: 2, height: 5)
    board.display.fillRect(x: 28, y: 80, width: 2, height: 1)
    board.display.fillRect(x: 28, y: 82, width: 1, height: 1)
    board.display.fillRect(x: 28, y: 84, width: 2, height: 1)
    board.display.fillRect(x: 33, y: 80, width: 3, height: 1)
    board.display.fillRect(x: 33, y: 81, width: 1, height: 1)
    board.display.fillRect(x: 33, y: 82, width: 3, height: 1)
    board.display.fillRect(x: 35, y: 83, width: 1, height: 1)
    board.display.fillRect(x: 33, y: 84, width: 3, height: 1)
    board.display.fillRect(x: 38, y: 80, width: 3, height: 1)
    board.display.fillRect(x: 38, y: 81, width: 1, height: 1)
    board.display.fillRect(x: 38, y: 82, width: 3, height: 1)
    board.display.fillRect(x: 40, y: 83, width: 1, height: 1)
    board.display.fillRect(x: 38, y: 84, width: 3, height: 1)
    board.display.fillRect(x: 46, y: 81, width: 2, height: 4)
    board.display.fillRect(x: 51, y: 81, width: 2, height: 4)
    board.display.fillRect(x: 48, y: 80, width: 3, height: 1)
    board.display.fillRect(x: 48, y: 83, width: 3, height: 1)
  }
}

// MARK: - Input

func handleInput(_ now: UInt32) {
  var cur: UInt8 = 0
  if Buttons.left { cur |= 1 }
  if Buttons.right { cur |= 2 }
  if Buttons.a { cur |= 4 }
  if Buttons.b { cur |= 8 }
  if Buttons.up { cur |= 16 }
  if Buttons.down { cur |= 32 }

  let pressed = cur & ~lastButtons
  lastButtons = cur

  if pressed & 4 != 0 { Tetris.rotate() }
  if pressed & 8 != 0 { Tetris.rotateCCW() }
  if pressed & 16 != 0 {
    Tetris.hardDrop()
    lastFallMs = SysTick.milliseconds
  }

  if now &- lastInputMs >= 120 {
    if cur & 1 != 0 {
      Tetris.moveLeft()
      lastInputMs = now
    } else if cur & 2 != 0 {
      Tetris.moveRight()
      lastInputMs = now
    }
  }

  if cur & 32 != 0 && now &- lastDownMs >= 50 {
    if !Tetris.moveDown() { Tetris.lockAndSpawn() }
    lastDownMs = now
    lastFallMs = now
  }
}

// MARK: - Rendering

func renderGame() {
  board.display.clear()
  board.display.drawScore(Tetris.score, x: 1, y: 0)
  board.display.drawDigit(UInt8(Tetris.level % 10), x: 55, y: 0)

  for r in 0..<4 {
    for c in 0..<4 {
      if Piece.isFilled(type: Tetris.nxtPiece, rotation: 0, row: r, col: c) {
        board.display.fillRect(x: 44 + c * 3, y: r * 3, width: 2, height: 2)
      }
    }
  }

  let bw = Tetris.cols * cellSize
  for y in boardTop..<(boardTop + Tetris.rows * cellSize) {
    board.display.setPixel(x: boardLeft - 1, y: y)
    board.display.setPixel(x: boardLeft + bw, y: y)
  }
  for x in (boardLeft - 1)...(boardLeft + bw) {
    board.display.setPixel(x: x, y: boardTop + Tetris.rows * cellSize)
  }

  for r in 0..<Tetris.rows {
    let row = Tetris.getRow(r)
    if row == 0 { continue }
    for c in 0..<Tetris.cols {
      if row & UInt16(1 << c) != 0 { drawCell(c, r) }
    }
  }

  for r in 0..<4 {
    for c in 0..<4 {
      if Piece.isFilled(type: Tetris.curPiece, rotation: Tetris.curRot, row: r, col: c) {
        let bx = Tetris.curX + c
        let by = Tetris.curY + r
        if by >= 0 { drawCell(bx, by) }
      }
    }
  }
}

func drawCell(_ col: Int, _ row: Int) {
  board.display.fillRect(
    x: boardLeft + col * cellSize, y: boardTop + row * cellSize,
    width: cellSize - 1, height: cellSize - 1
  )
}

// MARK: - Game Over

func gameOverUpdate() {
  if Buttons.a || Buttons.b {
    Music.initialize()
    gameState = 0
    lastButtons = 0xFF
  }
}

func renderGameOver() {
  board.display.clear()

  for r in 0..<Tetris.rows {
    let row = Tetris.getRow(r)
    if row == 0 { continue }
    for c in 0..<Tetris.cols {
      if row & UInt16(1 << c) != 0 && (r + c) % 2 == 0 {
        drawCell(c, r)
      }
    }
  }

  // G
  board.display.fillRect(x: 4, y: 44, width: 7, height: 2)
  board.display.fillRect(x: 4, y: 44, width: 2, height: 9)
  board.display.fillRect(x: 4, y: 51, width: 7, height: 2)
  board.display.fillRect(x: 9, y: 48, width: 2, height: 5)
  board.display.fillRect(x: 7, y: 48, width: 2, height: 2)
  // A
  board.display.fillRect(x: 13, y: 46, width: 2, height: 7)
  board.display.fillRect(x: 18, y: 46, width: 2, height: 7)
  board.display.fillRect(x: 15, y: 44, width: 3, height: 2)
  board.display.fillRect(x: 15, y: 49, width: 3, height: 2)
  // M
  board.display.fillRect(x: 22, y: 44, width: 2, height: 9)
  board.display.fillRect(x: 29, y: 44, width: 2, height: 9)
  board.display.fillRect(x: 24, y: 46, width: 2, height: 2)
  board.display.fillRect(x: 27, y: 46, width: 2, height: 2)
  // E
  board.display.fillRect(x: 33, y: 44, width: 2, height: 9)
  board.display.fillRect(x: 33, y: 44, width: 7, height: 2)
  board.display.fillRect(x: 33, y: 48, width: 5, height: 2)
  board.display.fillRect(x: 33, y: 51, width: 7, height: 2)
  // O
  board.display.fillRect(x: 4, y: 58, width: 2, height: 9)
  board.display.fillRect(x: 9, y: 58, width: 2, height: 9)
  board.display.fillRect(x: 6, y: 58, width: 3, height: 2)
  board.display.fillRect(x: 6, y: 65, width: 3, height: 2)
  // V
  board.display.fillRect(x: 13, y: 58, width: 2, height: 6)
  board.display.fillRect(x: 18, y: 58, width: 2, height: 6)
  board.display.fillRect(x: 15, y: 64, width: 3, height: 2)
  // E
  board.display.fillRect(x: 22, y: 58, width: 2, height: 9)
  board.display.fillRect(x: 22, y: 58, width: 7, height: 2)
  board.display.fillRect(x: 22, y: 62, width: 5, height: 2)
  board.display.fillRect(x: 22, y: 65, width: 7, height: 2)
  // R
  board.display.fillRect(x: 31, y: 58, width: 2, height: 9)
  board.display.fillRect(x: 31, y: 58, width: 7, height: 2)
  board.display.fillRect(x: 36, y: 60, width: 2, height: 2)
  board.display.fillRect(x: 31, y: 62, width: 7, height: 2)
  board.display.fillRect(x: 36, y: 64, width: 2, height: 3)

  board.display.drawScore(Tetris.score, x: 16, y: 76)

  if frameCount / 10 % 2 == 0 {
    board.display.fillRect(x: 16, y: 92, width: 32, height: 2)
  }
}
