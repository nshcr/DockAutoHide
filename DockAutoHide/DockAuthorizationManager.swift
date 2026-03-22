import AppKit
import ApplicationServices
import Combine
import Foundation

enum DockAuthorizationState: String {
  case authorized
  case denied
  case notDetermined
}

/// Authorization layer for System Events automation permission.
final class DockAuthorizationManager: ObservableObject {
  @Published private(set) var state: DockAuthorizationState = .notDetermined

  private let targetBundleID = "com.apple.systemevents"
  private let queue = DispatchQueue(
    label: "DockAutoHide.Authorization",
    qos: .utility
  )

  func requestAccessOnLaunch() {
    requestAccess(prompt: true, activateApp: true, reason: "launch")
  }

  func requestAccessFromUser() {
    requestAccess(prompt: true, activateApp: true, reason: "user")
  }

  func refreshStatus() {
    requestAccess(prompt: false, activateApp: false, reason: "refresh")
  }

  private func requestAccess(prompt: Bool, activateApp: Bool, reason: String) {
    queue.async {
      guard self.ensureSystemEventsRunning() else {
        DockLogger.log(
          "Authorization: System Events not running; reason=\(reason)"
        )
        self.updateState(.notDetermined)
        return
      }

      let frontmost = NSWorkspace.shared.frontmostApplication
      if activateApp {
        DispatchQueue.main.sync {
          NSApp.activate(ignoringOtherApps: true)
        }
      }

      let status = self.determinePermission(prompt: prompt)
      let mapped = self.mapStatus(status)
      DockLogger.log(
        "Authorization result: \(status) mapped=\(mapped.rawValue), reason=\(reason)"
      )
      self.updateState(mapped)

      if activateApp {
        self.restoreFrontmost(frontmost)
      }
    }
  }

  private func determinePermission(prompt: Bool) -> OSStatus {
    var target = AEAddressDesc()
    let createStatus = targetBundleID.withCString { ptr in
      AECreateDesc(
        DescType(typeApplicationBundleID),
        ptr,
        Int(strlen(ptr)),
        &target
      )
    }
    guard createStatus == noErr else {
      DockLogger.log("Authorization AECreateDesc failed: \(createStatus)")
      return OSStatus(createStatus)
    }

    let permissionStatus = AEDeterminePermissionToAutomateTarget(
      &target,
      AEEventClass(typeWildCard),
      AEEventID(typeWildCard),
      prompt
    )
    AEDisposeDesc(&target)
    return permissionStatus
  }

  private func mapStatus(_ status: OSStatus) -> DockAuthorizationState {
    if status == noErr {
      return .authorized
    }
    if status == OSStatus(-1744) || status == procNotFound {
      return .notDetermined
    }
    return .denied
  }

  private func updateState(_ newState: DockAuthorizationState) {
    DispatchQueue.main.async {
      self.state = newState
    }
  }

  private func ensureSystemEventsRunning(timeout: TimeInterval = 1.0) -> Bool {
    if isSystemEventsRunning() {
      return true
    }
    guard
      let url = NSWorkspace.shared.urlForApplication(
        withBundleIdentifier: targetBundleID
      )
    else {
      DockLogger.log("Authorization: System Events URL not found")
      return false
    }

    let semaphore = DispatchSemaphore(value: 0)
    DispatchQueue.main.async {
      let config = NSWorkspace.OpenConfiguration()
      config.activates = false
      config.addsToRecentItems = false
      NSWorkspace.shared.openApplication(at: url, configuration: config) {
        _,
        _ in
        semaphore.signal()
      }
    }
    _ = semaphore.wait(timeout: .now() + timeout)
    return isSystemEventsRunning()
  }

  private func isSystemEventsRunning() -> Bool {
    return !NSRunningApplication.runningApplications(
      withBundleIdentifier: targetBundleID
    ).isEmpty
  }

  private func restoreFrontmost(_ app: NSRunningApplication?) {
    guard let app, app.bundleIdentifier != Bundle.main.bundleIdentifier else {
      return
    }
    DispatchQueue.main.async {
      _ = app.activate(options: [.activateAllWindows])
    }
  }
}
