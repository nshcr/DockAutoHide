import SwiftUI

@main
struct DockAutoHideApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

  var body: some Scene {
    // Use an empty Settings scene to avoid showing a window.
    Settings {
      EmptyView()
    }
  }
}

// App Delegate manages the menu bar app.
class AppDelegate: NSObject, NSApplicationDelegate {
  private var menuBarManager: MenuBarManager?
  private var dockManager = DockManager()
  private var launchAtLoginManager = LaunchAtLoginManager()

  func applicationDidFinishLaunching(_ notification: Notification) {
    // Hide Dock icon.
    NSApp.setActivationPolicy(.accessory)

    // Create the menu bar manager.
    menuBarManager = MenuBarManager(
      dockManager: dockManager,
      launchAtLoginManager: launchAtLoginManager
    )
  }

  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication)
    -> Bool
  {
    return false
  }
}
