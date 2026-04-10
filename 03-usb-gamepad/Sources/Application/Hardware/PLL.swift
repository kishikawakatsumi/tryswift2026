/// Phase-locked loop — generates high-speed clocks from the 12MHz XOSC.
///
/// PLL formula: `f_out = (f_ref / REFDIV) x FBDIV / (POSTDIV1 x POSTDIV2)`
enum PLL {
  /// Configures a PLL with the given parameters.
  ///
  /// - PLL_SYS (0x4002_8000): `(12MHz / 1) x 125 / (6 x 2) = 125MHz`
  /// - PLL_USB (0x4002_C000): `(12MHz / 1) x 100 / (5 x 5) = 48MHz`
  static func initialize(
    base: UInt32, peripheral: Resets.Peripheral,
    fbdiv: UInt32, postDiv1: UInt32, postDiv2: UInt32
  ) {
    let cs = Register(address: base + 0x00)
    let power = Register(address: base + 0x04)
    let fbdivReg = Register(address: base + 0x08)
    let prim = Register(address: base + 0x0C)

    Resets.reset(peripheral)
    Resets.unreset(peripheral)

    cs.store(1)  // REFDIV = 1
    fbdivReg.store(fbdiv)

    // Power on PLL core and VCO (clear PD and VCOPD bits)
    power.clear((1 << 0) | (1 << 5))
    while cs.load() & (1 << 31) == 0 {}  // Wait for VCO lock

    prim.store((postDiv1 << 16) | (postDiv2 << 12))
    power.clear(1 << 3)  // Enable post dividers
  }
}
