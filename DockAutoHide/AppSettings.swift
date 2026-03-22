import Foundation

/// Configuration layer for persisted settings.
final class AppConfigurationStore {
  private let defaults: UserDefaults

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
  }

  private enum Keys {
    static let smartEnabled = "DockAutoHide.smartEnabled"
    static let manualAutoHideEnabled = "DockAutoHide.manualAutoHideEnabled"
  }

  func readSmartEnabled() -> Bool? {
    return defaults.object(forKey: Keys.smartEnabled) as? Bool
  }

  func writeSmartEnabled(_ value: Bool) {
    defaults.set(value, forKey: Keys.smartEnabled)
  }

  func readManualAutoHideEnabled() -> Bool? {
    return defaults.object(forKey: Keys.manualAutoHideEnabled) as? Bool
  }

  func writeManualAutoHideEnabled(_ value: Bool) {
    defaults.set(value, forKey: Keys.manualAutoHideEnabled)
  }
}
