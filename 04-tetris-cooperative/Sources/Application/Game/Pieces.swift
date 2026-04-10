/// Tetromino piece definitions with 4 rotation states.
///
/// Each piece is a 4x4 bitmask encoded as UInt16.
/// Bit n = row (n/4), col (n%4). Row 0 is top, col 0 is left.
enum Piece {
  /// Returns the 4x4 bitmask for piece type (0-6) at rotation (0-3).
  static func shape(type: UInt8, rotation: UInt8) -> UInt16 {
    let t = Int(type)
    let r = Int(rotation & 3)
    switch t {
    case 0:  // I
      switch r {
      case 0: return 0x00F0
      case 1: return 0x4444
      case 2: return 0x0F00
      default: return 0x2222
      }
    case 1:  // O
      return 0x0066
    case 2:  // T
      switch r {
      case 0: return 0x0072
      case 1: return 0x0262
      case 2: return 0x0270
      default: return 0x0232
      }
    case 3:  // S
      switch r {
      case 0: return 0x0036
      case 1: return 0x0462
      case 2: return 0x0360
      default: return 0x0231
      }
    case 4:  // Z
      switch r {
      case 0: return 0x0063
      case 1: return 0x0264
      case 2: return 0x0630
      default: return 0x0132
      }
    case 5:  // L
      switch r {
      case 0: return 0x0074
      case 1: return 0x0622
      case 2: return 0x0170
      default: return 0x0223
      }
    case 6:  // J
      switch r {
      case 0: return 0x0071
      case 1: return 0x0226
      case 2: return 0x0470
      default: return 0x0322
      }
    default: return 0
    }
  }

  /// Returns true if cell (row, col) in the 4x4 grid is filled.
  static func isFilled(type: UInt8, rotation: UInt8, row: Int, col: Int) -> Bool {
    let s = shape(type: type, rotation: rotation)
    return s & (1 << (row * 4 + col)) != 0
  }
}
