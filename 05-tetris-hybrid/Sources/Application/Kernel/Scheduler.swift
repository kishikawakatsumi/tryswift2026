/// Simple cooperative scheduler for periodic task execution.
///
/// Tasks are registered with an interval in milliseconds. The scheduler
/// checks each task on every iteration and calls it when its interval
/// has elapsed. Tasks must return quickly (non-blocking).
/// Tasks cannot be interrupted by other tasks.
enum Scheduler {
  typealias Action = @convention(c) () -> Void

  private struct Task {
    let handler: Action
    let interval: UInt32
    var lastRun: UInt32
  }

  private static let maxTasks = 8
  nonisolated(unsafe) private static var tasks: (Task?, Task?, Task?, Task?, Task?, Task?, Task?, Task?) =
    (nil, nil, nil, nil, nil, nil, nil, nil)
  nonisolated(unsafe) private static var count = 0

  /// Registers a periodic task.
  static func addTask(interval: UInt32, _ handler: Action) {
    let task = Task(
      handler: handler, interval: interval,
      lastRun: SysTick.milliseconds)
    switch count {
    case 0: tasks.0 = task
    case 1: tasks.1 = task
    case 2: tasks.2 = task
    case 3: tasks.3 = task
    case 4: tasks.4 = task
    case 5: tasks.5 = task
    case 6: tasks.6 = task
    case 7: tasks.7 = task
    default: return
    }
    count += 1
  }

  /// Runs the scheduler loop. This function never returns.
  static func run() -> Never {
    while true {
      let now = SysTick.milliseconds
      checkAndRun(&tasks.0, now: now)
      checkAndRun(&tasks.1, now: now)
      checkAndRun(&tasks.2, now: now)
      checkAndRun(&tasks.3, now: now)
      checkAndRun(&tasks.4, now: now)
      checkAndRun(&tasks.5, now: now)
      checkAndRun(&tasks.6, now: now)
      checkAndRun(&tasks.7, now: now)
    }
  }

  private static func checkAndRun(_ task: inout Task?, now: UInt32) {
    guard var t = task else { return }
    if now &- t.lastRun >= t.interval {
      t.handler()
      t.lastRun = now
      task = t
    }
  }
}
