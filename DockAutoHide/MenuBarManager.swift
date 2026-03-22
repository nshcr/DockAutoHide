import Cocoa
import Combine
import SwiftUI

/// Menu bar controller for the status item and menu.
class MenuBarManager {
  private var statusItem: NSStatusItem?
  private let dockManager: DockManager
  private let launchAtLoginManager: LaunchAtLoginManager
  private var cancellables = Set<AnyCancellable>()

  init(dockManager: DockManager, launchAtLoginManager: LaunchAtLoginManager) {
    self.dockManager = dockManager
    self.launchAtLoginManager = launchAtLoginManager
    setupMenuBar()

    // Observe DockManager updates.
    dockManager.objectWillChange
      .receive(on: DispatchQueue.main)
      .sink { [weak self] _ in
        // Schedule on the next run loop so @Published values have updated.
        DispatchQueue.main.async {
          self?.updateMenu()
        }
      }
      .store(in: &cancellables)
  }

  /// Configures the status item and menu.
  private func setupMenuBar() {
    statusItem = NSStatusBar.system
      .statusItem(withLength: NSStatusItem.squareLength)

    if let button = statusItem?.button {
      button.image = NSImage(
        systemSymbolName: "dock.rectangle",
        accessibilityDescription: "DockAutoHide"
      )
      button.toolTip = "DockAutoHide"
    }

    updateMenu()
  }

  /// Rebuilds the menu.
  private func updateMenu() {
    let menu = NSMenu()

    let isAuthorized = dockManager.isAuthorized

    // Smart switching.
    let smartItem = NSMenuItem(
      title: "Smart Switching",
      action: #selector(toggleSmartEnabled),
      keyEquivalent: ""
    )
    smartItem.target = self
    smartItem.state = dockManager.smartEnabled ? .on : .off
    smartItem.isEnabled = isAuthorized
    menu.addItem(smartItem)

    // Manual Dock auto-hide.
    let manualItem = NSMenuItem(
      title: "Dock Auto-Hide",
      action: #selector(toggleManualAutoHide),
      keyEquivalent: ""
    )
    manualItem.target = self
    manualItem.state = dockManager.manualAutoHideEnabled ? .on : .off
    manualItem.isEnabled = isAuthorized && !dockManager.smartEnabled
    menu.addItem(manualItem)

    let statusTitle: String
    if isAuthorized {
      statusTitle =
        dockManager.currentAutoHideEnabled
        ? "Status: Auto-hide On" : "Status: Auto-hide Off"
    } else {
      statusTitle = "Status: Not Authorized"
    }
    let statusMenuItem = NSMenuItem(
      title: statusTitle,
      action: nil,
      keyEquivalent: ""
    )
    statusMenuItem.isEnabled = false
    menu.addItem(statusMenuItem)

    if let errorMessage = dockManager.lastErrorMessage {
      let errorItem = NSMenuItem(
        title: "Error: \(errorMessage)",
        action: nil,
        keyEquivalent: ""
      )
      errorItem.isEnabled = false
      menu.addItem(errorItem)
    }

    if !isAuthorized {
      let authItem = NSMenuItem(
        title: "Request System Events Permission",
        action: #selector(requestAuthorization),
        keyEquivalent: ""
      )
      authItem.target = self
      menu.addItem(authItem)
    }

    menu.addItem(NSMenuItem.separator())

    // Launch at login.
    let launchAtLoginItem = NSMenuItem(
      title: "Launch at Login",
      action: #selector(toggleLaunchAtLogin),
      keyEquivalent: ""
    )
    launchAtLoginItem.target = self
    launchAtLoginItem.state = launchAtLoginManager.isEnabled ? .on : .off
    launchAtLoginItem.isEnabled = isAuthorized
    menu.addItem(launchAtLoginItem)

    menu.addItem(NSMenuItem.separator())

    let versionItem = NSMenuItem(
      title: versionMenuTitle(),
      action: nil,
      keyEquivalent: ""
    )
    versionItem.isEnabled = false
    menu.addItem(versionItem)

    // Quit.
    let quitItem = NSMenuItem(
      title: "Quit",
      action: #selector(quitApp),
      keyEquivalent: "q"
    )
    quitItem.target = self
    menu.addItem(quitItem)

    // Setting the status item's menu while the menu/button is being laid out
    // or while the menu is open can trigger AppKit layout recursion. If the
    // button is highlighted (menu open), defer the replacement to the next
    // run loop iteration to avoid calling into layout while AppKit is busy.
    if let button = statusItem?.button, button.isHighlighted {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
        self?.statusItem?.menu = menu
      }
    } else {
      statusItem?.menu = menu
    }
  }

  /// Toggles smart switching.
  @objc private func toggleSmartEnabled() {
    let newState = !dockManager.smartEnabled
    dockManager.setSmartEnabled(newState)
    DockLogger
      .log("User toggled smart switching: \(newState ? "enabled" : "disabled")")
  }

  @objc private func toggleManualAutoHide() {
    let newState = !dockManager.manualAutoHideEnabled
    dockManager.setManualAutoHideEnabled(newState)
    DockLogger
      .log("User toggled Dock auto-hide: \(newState ? "enabled" : "disabled")")
  }

  @objc private func requestAuthorization() {
    dockManager.requestAuthorizationFromUser()
    DockLogger.log("User requested System Events permission")
  }

  /// Toggles launch at login.
  @objc private func toggleLaunchAtLogin() {
    launchAtLoginManager.toggle()
    updateMenu()
  }

  /// Quits the app.
  @objc private func quitApp() {
    NSApplication.shared.terminate(nil)
  }

  private func versionMenuTitle() -> String {
    let shortVersion =
      Bundle.main.object(
        forInfoDictionaryKey: "CFBundleShortVersionString"
      ) as? String ?? "0.0.0"
    let buildNumber =
      Bundle.main.object(
        forInfoDictionaryKey: "CFBundleVersion"
      ) as? String ?? "0"
    return "Version: v\(shortVersion) (\(buildNumber))"
  }

  /// Releases the status item.
  deinit {
    statusItem = nil
  }
}
