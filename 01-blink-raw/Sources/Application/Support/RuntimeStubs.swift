// Minimal runtime stubs for Embedded Swift on bare-metal ARM (armv6m).
//
// With -nostdlib, the compiler still expects a few symbols.
// On single-core Cortex-M0+, plain load/store is sufficient for atomics.

@c
func __atomic_load_4(_ ptr: UnsafePointer<UInt32>, _ memorder: Int32) -> UInt32 {
  ptr.pointee
}

@c
func __atomic_store_4(_ ptr: UnsafeMutablePointer<UInt32>, _ value: UInt32, _ memorder: Int32) {
  ptr.pointee = value
}
