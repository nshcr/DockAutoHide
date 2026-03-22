import Foundation

enum DockLogger {
  static var isEnabled: Bool = true

  static func log(_ message: String) {
    guard isEnabled else { return }
    let timestamp = ISO8601DateFormatter().string(from: Date())
    print("[DockAutoHide] \(timestamp) \(message)")
  }
}
