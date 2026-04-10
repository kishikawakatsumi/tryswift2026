/// Tetris game logic. Board is 10 columns x 20 rows. Row 0 is top.
enum Tetris {
  static let cols = 10
  static let rows = 20

  nonisolated(unsafe) static var boardRows:
    (
      UInt16, UInt16, UInt16, UInt16, UInt16,
      UInt16, UInt16, UInt16, UInt16, UInt16,
      UInt16, UInt16, UInt16, UInt16, UInt16,
      UInt16, UInt16, UInt16, UInt16, UInt16
    ) = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)

  nonisolated(unsafe) static var curPiece: UInt8 = 0
  nonisolated(unsafe) static var curRot: UInt8 = 0
  nonisolated(unsafe) static var curX: Int = 3
  nonisolated(unsafe) static var curY: Int = 0
  nonisolated(unsafe) static var nxtPiece: UInt8 = 0
  nonisolated(unsafe) static var score: UInt32 = 0
  nonisolated(unsafe) static var level: UInt32 = 1
  nonisolated(unsafe) static var tLines: UInt32 = 0
  nonisolated(unsafe) static var gameOver = false

  nonisolated(unsafe) private static var rng: UInt32 = 42

  private static func random7() -> UInt8 {
    rng ^= rng << 13
    rng ^= rng >> 17
    rng ^= rng << 5
    return UInt8(rng % 7)
  }

  static func getRow(_ r: Int) -> UInt16 {
    withUnsafePointer(to: &boardRows) { ptr in
      UnsafeRawPointer(ptr).assumingMemoryBound(to: UInt16.self)[r]
    }
  }
  private static func setRow(_ r: Int, _ v: UInt16) {
    withUnsafeMutablePointer(to: &boardRows) { ptr in
      UnsafeMutableRawPointer(ptr).assumingMemoryBound(to: UInt16.self)[r] = v
    }
  }

  static func initialize() {
    for r in 0..<rows { setRow(r, 0) }
    score = 0
    tLines = 0
    level = 1
    gameOver = false
    rng = SysTick.milliseconds | 1
    curPiece = random7()
    nxtPiece = random7()
    curRot = 0
    curX = 3
    curY = -1
  }

  static func canPlace(_ type: UInt8, _ rot: UInt8, _ px: Int, _ py: Int) -> Bool {
    for r in 0..<4 {
      for c in 0..<4 {
        if Piece.isFilled(type: type, rotation: rot, row: r, col: c) {
          let bx = px + c
          let by = py + r
          if bx < 0 || bx >= cols || by >= rows { return false }
          if by >= 0 && getRow(by) & UInt16(1 << bx) != 0 { return false }
        }
      }
    }
    return true
  }

  static func moveLeft() { if canPlace(curPiece, curRot, curX - 1, curY) { curX -= 1 } }
  static func moveRight() { if canPlace(curPiece, curRot, curX + 1, curY) { curX += 1 } }
  static func rotate() {
    let nr = (curRot + 1) & 3
    if canPlace(curPiece, nr, curX, curY) { curRot = nr }
  }
  static func rotateCCW() {
    let nr = (curRot + 3) & 3
    if canPlace(curPiece, nr, curX, curY) { curRot = nr }
  }
  static func moveDown() -> Bool {
    if canPlace(curPiece, curRot, curX, curY + 1) {
      curY += 1
      return true
    }
    return false
  }
  static func hardDrop() {
    while canPlace(curPiece, curRot, curX, curY + 1) {
      curY += 1
      score &+= 2
    }
    lockAndSpawn()
  }
  static func lockAndSpawn() {
    lockPiece()
    let cleared = clearLines()
    if cleared > 0 {
      switch cleared {
      case 1: score &+= 40 &* level
      case 2: score &+= 100 &* level
      case 3: score &+= 300 &* level
      default: score &+= 1200 &* level
      }
      tLines &+= UInt32(cleared)
      level = tLines / 10 &+ 1
    }
    curPiece = nxtPiece
    nxtPiece = random7()
    curRot = 0
    curX = 3
    curY = -1
    if !canPlace(curPiece, curRot, curX, curY) { gameOver = true }
  }
  private static func lockPiece() {
    for r in 0..<4 {
      for c in 0..<4 {
        if Piece.isFilled(type: curPiece, rotation: curRot, row: r, col: c) {
          let by = curY + r
          let bx = curX + c
          if by >= 0 && by < rows && bx >= 0 && bx < cols {
            setRow(by, getRow(by) | UInt16(1 << bx))
          }
        }
      }
    }
  }
  private static func clearLines() -> UInt8 {
    let full: UInt16 = (1 << cols) - 1
    var cleared: UInt8 = 0
    var dst = rows - 1
    var src = rows - 1
    while src >= 0 {
      if getRow(src) == full {
        cleared += 1
        src -= 1
        continue
      }
      if dst != src { setRow(dst, getRow(src)) }
      dst -= 1
      src -= 1
    }
    while dst >= 0 {
      setRow(dst, 0)
      dst -= 1
    }
    return cleared
  }
  static var fallInterval: UInt32 {
    let base: UInt32 = 500
    let dec = (level &- 1) &* 40
    return dec >= base ? 50 : base &- dec
  }
}
