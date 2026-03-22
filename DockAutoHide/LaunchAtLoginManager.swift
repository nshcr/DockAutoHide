import Combine
import Foundation
import ServiceManagement

/// Manages launch-at-login behavior.
class LaunchAtLoginManager: ObservableObject {
  @Published var isEnabled: Bool = false

  private let bundleIdentifier = "io.github.nshcr.DockAutoHide"

  init() {
    checkLaunchAtLoginStatus()
  }

  /// Sets launch-at-login state.
  func setLaunchAtLogin(_ enabled: Bool) {
    do {
      if enabled {
        try SMAppService.mainApp.register()
        DockLogger.log("Launch at login enabled.")
      } else {
        try SMAppService.mainApp.unregister()
        DockLogger.log("Launch at login disabled.")
      }
      isEnabled = enabled
    } catch {
      DockLogger.log("Failed to set launch at login: \(error)")
    }
  }

  /// Checks current launch-at-login state.
  private func checkLaunchAtLoginStatus() {
    isEnabled = SMAppService.mainApp.status == .enabled
  }

  /// Toggles launch-at-login state.
  func toggle() {
    setLaunchAtLogin(!isEnabled)
  }
}
