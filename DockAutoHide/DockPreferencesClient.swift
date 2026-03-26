import CoreFoundation
import Foundation

final class DockPreferencesClient {
  private let appID = "com.apple.dock" as CFString

  func readOrientation() -> String? {
    readValue(forKey: "orientation" as CFString) as? String
  }

  func readTileSize() -> Double? {
    guard let value = readValue(forKey: "tilesize" as CFString) else {
      return nil
    }
    return doubleValue(from: value)
  }

  func readLargeSize() -> Double? {
    guard let value = readValue(forKey: "largesize" as CFString) else {
      return nil
    }
    return doubleValue(from: value)
  }

  func readMagnificationEnabled() -> Bool? {
    guard let value = readValue(forKey: "magnification" as CFString) else {
      return nil
    }
    return boolValue(from: value)
  }

  private func readValue(forKey key: CFString) -> Any? {
    if let value = CFPreferencesCopyValue(
      key,
      appID,
      kCFPreferencesCurrentUser,
      kCFPreferencesAnyHost
    ) {
      return value
    }
    if let value = CFPreferencesCopyValue(
      key,
      appID,
      kCFPreferencesCurrentUser,
      kCFPreferencesCurrentHost
    ) {
      return value
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

  private func boolValue(from value: Any) -> Bool? {
    if let number = value as? NSNumber {
      return number.boolValue
    }
    if let boolValue = value as? Bool {
      return boolValue
    }
    return nil
  }
}
