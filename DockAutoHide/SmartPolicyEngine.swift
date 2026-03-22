import Foundation

final class SmartPolicyEngine {
  var onDecision: ((Bool, String) -> Void)?

  private let evaluator: DockWindowOverlapEvaluator
  private let queue = DispatchQueue(
    label: "DockAutoHide.SmartPolicy",
    qos: .utility
  )
  private var timer: DispatchSourceTimer?

  private var lastObserved: Bool?
  private var lastReported: Bool?
  private var stableCount: Int = 0

  private let interval: TimeInterval = 0.1
  private let requiredStableSamples: Int = 1

  init(evaluator: DockWindowOverlapEvaluator) {
    self.evaluator = evaluator
  }

  func start() {
    stop()
    let timer = DispatchSource.makeTimerSource(queue: queue)
    timer.schedule(deadline: .now(), repeating: interval)
    timer.setEventHandler { [weak self] in
      self?.tick()
    }
    timer.resume()
    self.timer = timer
  }

  func stop() {
    timer?.cancel()
    timer = nil
    lastObserved = nil
    lastReported = nil
    stableCount = 0
  }

  private func tick() {
    guard let decision = evaluator.evaluate() else {
      return
    }

    if decision.shouldAutoHide == lastObserved {
      stableCount += 1
    } else {
      lastObserved = decision.shouldAutoHide
      stableCount = 1
    }

    if stableCount >= requiredStableSamples,
      lastReported != decision.shouldAutoHide
    {
      lastReported = decision.shouldAutoHide
      DockLogger
        .log(
          "Smart decision: autohide=\(decision.shouldAutoHide), reason=\(decision.reason)"
        )
      onDecision?(decision.shouldAutoHide, decision.reason)
    }
  }
}
