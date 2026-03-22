import Combine
import Foundation

/// Core coordinator: authorization + automation + configuration.
final class DockManager: ObservableObject {
  @Published var smartEnabled: Bool
  @Published var manualAutoHideEnabled: Bool
  @Published private(set) var currentAutoHideEnabled: Bool
  @Published private(set) var lastErrorMessage: String?
  @Published private(set) var authorizationState: DockAuthorizationState

  private let prefsClient: DockPreferencesClient
  private let automationService: DockAutomationService
  private let authorizationManager: DockAuthorizationManager
  private let configStore: AppConfigurationStore
  private let engine: SmartPolicyEngine
  private var cancellables = Set<AnyCancellable>()

  private var pendingSmartWork: DispatchWorkItem?
  private var pendingSmartState: Bool?
  private var lastSmartApplyAt: Date?
  private let smartDebounce: TimeInterval = 0.0
  private let smartCooldown: TimeInterval = 0.1
  private var pendingApplyWork: DispatchWorkItem?
  private var pendingApplyState: Bool?
  private var pendingApplySource: ApplySource?
  private var pendingApplyReason: String?
  private let applyCoalesceWindow: TimeInterval = 0.3

  init(
    prefsClient: DockPreferencesClient = DockPreferencesClient(),
    automationService: DockAutomationService = DockAutomationService(),
    authorizationManager: DockAuthorizationManager = DockAuthorizationManager(),
    configStore: AppConfigurationStore = AppConfigurationStore(),
    engine: SmartPolicyEngine? = nil
  ) {
    self.prefsClient = prefsClient
    self.automationService = automationService
    self.authorizationManager = authorizationManager
    self.configStore = configStore
    let evaluator = DockWindowOverlapEvaluator(prefsClient: prefsClient)
    self.engine = engine ?? SmartPolicyEngine(evaluator: evaluator)

    let storedSmartEnabled = configStore.readSmartEnabled() ?? false
    let storedManualEnabled = configStore.readManualAutoHideEnabled()

    self.smartEnabled = storedSmartEnabled
    self.manualAutoHideEnabled = storedManualEnabled ?? false
    self.currentAutoHideEnabled = false
    self.lastErrorMessage = nil
    self.authorizationState = authorizationManager.state

    DockLogger.log(
      "Init: smartEnabled=\(smartEnabled), manualAutoHide=\(manualAutoHideEnabled), auth=\(authorizationState.rawValue)"
    )
    if !ScreenCapturePermission.hasAccess {
      DockLogger.log(
        "Screen recording permission not granted; smart overlap detection may be inaccurate"
      )
    }

    configureEngine()
    bindAuthorization()
    authorizationManager.requestAccessOnLaunch()
  }

  var isAuthorized: Bool {
    return authorizationState == .authorized
  }

  func requestAuthorizationFromUser() {
    authorizationManager.requestAccessFromUser()
  }

  func setSmartEnabled(_ enabled: Bool) {
    guard isAuthorized else {
      lastErrorMessage =
        "System Events permission is required to use this feature."
      DockLogger.log("Smart toggle ignored: not authorized")
      return
    }
    DockLogger.log("Set smartEnabled=\(enabled)")
    smartEnabled = enabled
    configStore.writeSmartEnabled(enabled)

    if enabled {
      startSmartMode()
    } else {
      stopSmartMode()
      applyManualState(reason: "smartDisabled")
    }
  }

  func setManualAutoHideEnabled(_ enabled: Bool) {
    guard isAuthorized else {
      lastErrorMessage =
        "System Events permission is required to use this feature."
      DockLogger.log("Manual toggle ignored: not authorized")
      return
    }
    DockLogger.log("Set manualAutoHideEnabled=\(enabled)")
    manualAutoHideEnabled = enabled
    configStore.writeManualAutoHideEnabled(enabled)

    if !smartEnabled {
      applyManualState(reason: "manualToggle")
    }
  }

  private func configureEngine() {
    engine.onDecision = { [weak self] shouldAutoHide, _ in
      guard let self else { return }
      DispatchQueue.main.async {
        self.scheduleSmartApply(shouldAutoHide)
      }
    }
  }

  private func bindAuthorization() {
    authorizationManager.$state
      .receive(on: DispatchQueue.main)
      .sink { [weak self] state in
        self?.handleAuthorizationStateChange(state)
      }
      .store(in: &cancellables)
  }

  private func handleAuthorizationStateChange(_ state: DockAuthorizationState) {
    authorizationState = state
    switch state {
    case .authorized:
      lastErrorMessage = nil
      let storedSmartEnabled = configStore.readSmartEnabled() ?? false
      smartEnabled = storedSmartEnabled
      if let systemValue = automationService.readAutoHide() {
        currentAutoHideEnabled = systemValue
        if let storedManual = configStore.readManualAutoHideEnabled() {
          manualAutoHideEnabled = storedManual
        } else {
          manualAutoHideEnabled = systemValue
          configStore.writeManualAutoHideEnabled(systemValue)
        }
      }
      if smartEnabled {
        startSmartMode()
      } else {
        applyManualState(reason: "authGranted")
      }
    case .denied, .notDetermined:
      stopSmartMode()
      pendingSmartState = nil
      cancelPendingApply()
      smartEnabled = false
      manualAutoHideEnabled = false
      lastErrorMessage =
        "System Events permission is required to control the Dock."
    }
  }

  private func startSmartMode() {
    guard isAuthorized else { return }
    engine.start()
  }

  private func stopSmartMode() {
    engine.stop()
    pendingSmartWork?.cancel()
    pendingSmartWork = nil
    pendingSmartState = nil
  }

  private func cancelPendingApply() {
    pendingApplyWork?.cancel()
    pendingApplyWork = nil
    pendingApplyState = nil
    pendingApplySource = nil
    pendingApplyReason = nil
  }

  private func applyManualState(reason: String) {
    applyAutoHide(manualAutoHideEnabled, source: .manual, reason: reason)
  }

  private enum ApplySource {
    case manual
    case smart

    var label: String {
      switch self {
      case .manual:
        return "manual"
      case .smart:
        return "smart"
      }
    }
  }

  private func scheduleSmartApply(_ desired: Bool) {
    guard isAuthorized else { return }
    pendingSmartState = desired
    pendingSmartWork?.cancel()
    let work = DispatchWorkItem { [weak self] in
      self?.applySmartIfNeeded()
    }
    pendingSmartWork = work
    DispatchQueue.main.asyncAfter(
      deadline: .now() + smartDebounce,
      execute: work
    )
  }

  private func applySmartIfNeeded() {
    guard isAuthorized, let desired = pendingSmartState else {
      return
    }
    let now = Date()
    if let last = lastSmartApplyAt {
      let elapsed = now.timeIntervalSince(last)
      if elapsed < smartCooldown {
        let delay = smartCooldown - elapsed
        DockLogger.log(
          "Smart apply throttled, delay=\(String(format: "%.2f", delay))s, desired=\(desired)"
        )
        let work = DispatchWorkItem { [weak self] in
          self?.applySmartIfNeeded()
        }
        pendingSmartWork?.cancel()
        pendingSmartWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
        return
      }
    }
    applyAutoHide(desired, source: .smart, reason: "smartDecision")
  }

  private func applyAutoHide(
    _ enabled: Bool,
    source: ApplySource,
    reason: String
  ) {
    guard isAuthorized else {
      lastErrorMessage =
        "System Events permission is required to control the Dock."
      return
    }
    if currentAutoHideEnabled == enabled {
      if pendingApplyWork != nil {
        DockLogger.log(
          "Skip apply: coalesced to current \(enabled), source=\(source.label), reason=\(reason)"
        )
        cancelPendingApply()
      } else {
        DockLogger
          .log(
            "Skip apply: already \(enabled), source=\(source.label), reason=\(reason)"
          )
      }
      return
    }

    pendingApplyState = enabled
    pendingApplySource = source
    pendingApplyReason = reason
    pendingApplyWork?.cancel()
    let work = DispatchWorkItem { [weak self] in
      self?.flushPendingApply()
    }
    pendingApplyWork = work
    DispatchQueue.main.asyncAfter(
      deadline: .now() + applyCoalesceWindow,
      execute: work
    )
    DockLogger.log(
      "Apply queued: desired=\(enabled), source=\(source.label), reason=\(reason)"
    )
  }

  private func flushPendingApply() {
    guard isAuthorized else {
      return
    }
    guard let desired = pendingApplyState, let source = pendingApplySource
    else {
      return
    }
    let reason = pendingApplyReason ?? "unknown"
    cancelPendingApply()
    if desired == currentAutoHideEnabled {
      DockLogger.log(
        "Skip apply: coalesced to current \(desired), source=\(source.label), reason=\(reason)"
      )
      return
    }

    if source == .smart {
      lastSmartApplyAt = Date()
    }

    let success = automationService.setAutoHide(desired)
    if success {
      currentAutoHideEnabled = desired
      lastErrorMessage = nil
      DockLogger.log(
        "Apply success: autohide=\(desired), source=\(source.label), reason=\(reason)"
      )
    } else {
      lastErrorMessage = "Failed to apply Dock auto-hide via System Events."
      DockLogger.log(
        "Apply failed: autohide=\(desired), source=\(source.label), reason=\(reason)"
      )
    }
  }
}
