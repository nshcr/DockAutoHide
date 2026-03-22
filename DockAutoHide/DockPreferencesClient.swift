import CoreFoundation
import Foundation

final class DockPreferencesClient {
  private let appID = "com.apple.dock" as CFString

  func readOrientation() -> String? {
    if let value = CFPreferencesCopyValue(
      "orientation" as CFString,
      appID,
      kCFPreferencesCurrentUser,
      kCFPreferencesAnyHost
    ) {
      return value as? String
    }
    if let value = CFPreferencesCopyValue(
      "orientation" as CFString,
      appID,
      kCFPreferencesCurrentUser,
      kCFPreferencesCurrentHost
    ) {
      return value as? String
    }
    return nil
  }

  func readTileSize() -> Double? {
    if let value = CFPreferencesCopyValue(
      "tilesize" as CFString,
      appID,
      kCFPreferencesCurrentUser,
      kCFPreferencesAnyHost
    ) {
      return doubleValue(from: value)
    }
    if let value = CFPreferencesCopyValue(
      "tilesize" as CFString,
      appID,
      kCFPreferencesCurrentUser,
      kCFPreferencesCurrentHost
    ) {
      return doubleValue(from: value)
    }
    return nil
  }

  private func doubleValue(from value: Any) -> Double? {
    if let number = value as? NSNumber {
      return number.doubleValue
    }
    if let doubleValue = value as? Double {
      return doubleValue
    }
    return nil
  }
}
