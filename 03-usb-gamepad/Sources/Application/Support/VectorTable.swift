/// Default exception handler that halts the processor.
@c
func defaultHandler() {
  while true {}
}

/// Entry point called by the hardware on reset (via the vector table).
@c
func resetHandler() {
  initializeMemorySections()
  Application.main()
}

/// ARM Cortex-M0+ vector table.
///
/// The hardware reads this table on reset:
/// - `[0]` Initial stack pointer
/// - `[1]` Reset handler (entry point)
/// - `[2]` NMI handler
/// - `[3]` Hard fault handler
@used
@section(".vector")
let vectorTable:
  (
    UInt32,
    @convention(c) () -> Void,
    @convention(c) () -> Void,
    @convention(c) () -> Void
  ) = (
    0x2004_0000,
    resetHandler,
    defaultHandler,
    defaultHandler
  )
