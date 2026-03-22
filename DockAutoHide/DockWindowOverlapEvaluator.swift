import AppKit
import CoreGraphics
import Foundation

struct DockOverlapDecision {
  let shouldAutoHide: Bool
  let reason: String
}

final class DockWindowOverlapEvaluator {
  private let prefsClient: DockPreferencesClient
  private var loggedMissingDockFrame: Bool = false
  private var loggedDockCandidates: Bool = false

  init(prefsClient: DockPreferencesClient) {
    self.prefsClient = prefsClient
  }

  func evaluate() -> DockOverlapDecision? {
    let windows = windowList()
    let decisionInput: (dockFrames: [CGRect], source: String)
    if let dockFrame = dockFrame(from: windows) {
      decisionInput = ([dockFrame], "dockWindow")
    } else if let fallbackDockFrame = dockFrameFromPreferences() {
      decisionInput = ([fallbackDockFrame], "prefsFallback")
    } else {
      if !loggedMissingDockFrame {
        DockLogger.log("No dock frame available; skipping smart evaluation")
        loggedMissingDockFrame = true
      }
      return nil
    }
    loggedMissingDockFrame = false

    let overlaps = windowOverlapsDock(
      windows: windows,
      dockFrames: decisionInput.dockFrames
    )
    if overlaps {
      return DockOverlapDecision(
        shouldAutoHide: true,
        reason: "windowOverlap:\(decisionInput.source)"
      )
    }
    return DockOverlapDecision(
      shouldAutoHide: false,
      reason: "noOverlap:\(decisionInput.source)"
    )
  }

  private func windowList() -> [[String: Any]] {
    let options: CGWindowListOption = [
      .optionOnScreenOnly,
      .excludeDesktopElements,
    ]
    let info = CGWindowListCopyWindowInfo(options, kCGNullWindowID)
    return info as? [[String: Any]] ?? []
  }

  private func dockFrame(from windows: [[String: Any]]) -> CGRect? {
    let dockWindows = windows.compactMap {
      window -> (
        CGRect,
        Int,
        Double,
        Bool
      )? in
      guard let owner = window[kCGWindowOwnerName as String] as? String,
        owner == "Dock"
      else {
        return nil
      }
      guard let bounds = windowBounds(window) else {
        return nil
      }
      let layer = window[kCGWindowLayer as String] as? Int ?? 0
      let alpha = window[kCGWindowAlpha as String] as? Double ?? 1.0
      let isOnscreen = window[kCGWindowIsOnscreen as String] as? Bool ?? true
      return (bounds, layer, alpha, isOnscreen)
    }

    if dockWindows.isEmpty {
      return nil
    }

    let screenFrames = screenFramesInWindowCoordinates()
    let candidates = dockWindows.compactMap {
      bounds,
      layer,
      alpha,
      isOnscreen -> (
        CGRect,
        CGFloat,
        CGFloat
      )? in
      guard isOnscreen,
        alpha > 0
      else { return nil }
      guard let screen = nearestScreen(for: bounds, screens: screenFrames)
      else {
        return nil
      }
      guard
        let thicknessLength = dockThicknessAndLength(
          bounds: bounds,
          screen: screen
        )
      else {
        return nil
      }
      let thickness = thicknessLength.thickness
      let length = thicknessLength.length
      if thickness < 20 || thickness > 320 {
        return nil
      }
      if length < thickness * 2 {
        return nil
      }
      return (bounds, thickness, length)
    }

    if !loggedDockCandidates {
      let count = dockWindows.count
      let candidateCount = candidates.count
      DockLogger
        .log("Dock window candidates: \(count) total, \(candidateCount) usable")
      if let first = candidates.first {
        DockLogger
          .log(
            "Dock candidate example: frame=\(first.0), thickness=\(first.1), length=\(first.2)"
          )
      }
      loggedDockCandidates = true
    }

    if let best = candidates.sorted(by: { lhs, rhs in
      if lhs.1 == rhs.1 {
        return lhs.2 > rhs.2
      }
      return lhs.1 < rhs.1
    }).first {
      return best.0
    }

    return nil
  }

  private func windowOverlapsDock(
    windows: [[String: Any]],
    dockFrames: [CGRect]
  )
    -> Bool
  {
    let ignoredOwners: Set<String> = [
      "Dock",
      "WindowServer",
      "SystemUIServer",
      "Control Center",
      "Notification Center",
      "Spotlight",
      "loginwindow",
      "ScreenSaverEngine",
    ]

    for window in windows {
      guard let owner = window[kCGWindowOwnerName as String] as? String else {
        continue
      }
      if ignoredOwners.contains(owner) {
        continue
      }
      if let layer = window[kCGWindowLayer as String] as? Int, layer != 0 {
        continue
      }
      if let isOnscreen = window[kCGWindowIsOnscreen as String] as? Bool,
        isOnscreen == false
      {
        continue
      }
      if let alpha = window[kCGWindowAlpha as String] as? Double, alpha == 0 {
        continue
      }
      guard let bounds = windowBounds(window) else {
        continue
      }
      if dockFrames.contains(where: { bounds.intersects($0) }) {
        return true
      }
    }
    return false
  }

  private func dockFrameFromPreferences() -> CGRect? {
    let displayBounds: CGRect
    if let preferredScreen = preferredScreenForDockFallback() {
      let mainReferenceScreen = NSScreen.main ?? preferredScreen
      displayBounds = convertToWindowCoordinates(
        preferredScreen.frame,
        mainMaxY: mainReferenceScreen.frame.maxY
      )
    } else {
      displayBounds = CGDisplayBounds(CGMainDisplayID())
    }
    let orientation = prefsClient.readOrientation() ?? "bottom"
    let tileSize = prefsClient.readTileSize() ?? 64.0
    let thickness = max(36.0, tileSize + 16.0)

    switch orientation {
    case "left":
      return CGRect(
        x: displayBounds.minX,
        y: displayBounds.minY,
        width: thickness,
        height: displayBounds.height
      )
    case "right":
      return CGRect(
        x: displayBounds.maxX - thickness,
        y: displayBounds.minY,
        width: thickness,
        height: displayBounds.height
      )
    default:
      return CGRect(
        x: displayBounds.minX,
        y: displayBounds.maxY - thickness,
        width: displayBounds.width,
        height: thickness
      )
    }
  }

  private func preferredScreenForDockFallback() -> NSScreen? {
    let screens = NSScreen.screens
    guard !screens.isEmpty else {
      return nil
    }

    let mouseLocation = NSEvent.mouseLocation
    if let pointerScreen = screens.first(where: { screen in
      screen.frame.contains(mouseLocation)
    }) {
      return pointerScreen
    }

    return NSScreen.main ?? screens.first
  }

  private func windowBounds(_ window: [String: Any]) -> CGRect? {
    guard let boundsDict = window[kCGWindowBounds as String] as? [String: Any]
    else {
      return nil
    }
    guard let x = cgFloat(boundsDict["X"]),
      let y = cgFloat(boundsDict["Y"]),
      let width = cgFloat(boundsDict["Width"]),
      let height = cgFloat(boundsDict["Height"])
    else {
      return nil
    }
    return CGRect(x: x, y: y, width: width, height: height)
  }

  private func cgFloat(_ value: Any?) -> CGFloat? {
    if let number = value as? NSNumber {
      return CGFloat(truncating: number)
    }
    if let doubleValue = value as? Double {
      return CGFloat(doubleValue)
    }
    if let intValue = value as? Int {
      return CGFloat(intValue)
    }
    return nil
  }

  private func nearestScreen(for bounds: CGRect, screens: [CGRect]) -> CGRect? {
    if screens.isEmpty {
      return nil
    }
    var bestScreen = screens[0]
    var bestArea: CGFloat = 0
    for screen in screens {
      let intersection = bounds.intersection(screen)
      if intersection.isNull || intersection.isEmpty {
        continue
      }
      let area = intersection.width * intersection.height
      if area > bestArea {
        bestArea = area
        bestScreen = screen
      }
    }
    return bestArea > 0 ? bestScreen : nil
  }

  private func dockThicknessAndLength(bounds: CGRect, screen: CGRect) -> (
    thickness: CGFloat, length: CGFloat
  )? {
    let tolerance: CGFloat = 6
    if abs(bounds.minY - screen.minY) <= tolerance
      || abs(bounds.maxY - screen.maxY) <= tolerance
    {
      return (thickness: bounds.height, length: bounds.width)
    }
    if abs(bounds.minX - screen.minX) <= tolerance
      || abs(bounds.maxX - screen.maxX) <= tolerance
    {
      return (thickness: bounds.width, length: bounds.height)
    }
    return nil
  }

  private func screenFramesInWindowCoordinates() -> [CGRect] {
    guard let main = NSScreen.main ?? NSScreen.screens.first else {
      return []
    }
    let mainMaxY = main.frame.maxY
    // CGWindowList uses a global coordinate space with the origin at the top-left
    // of the main display. Convert NSScreen frames to match that space.
    return NSScreen.screens.map { screen in
      convertToWindowCoordinates(screen.frame, mainMaxY: mainMaxY)
    }
  }

  private func convertToWindowCoordinates(_ frame: CGRect, mainMaxY: CGFloat)
    -> CGRect
  {
    return CGRect(
      x: frame.minX,
      y: mainMaxY - frame.maxY,
      width: frame.width,
      height: frame.height
    )
  }
}
