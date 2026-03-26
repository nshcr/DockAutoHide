import AppKit
import CoreGraphics
import Foundation

struct DockOverlapDecision {
  let shouldAutoHide: Bool
  let reason: String
}

final class DockWindowOverlapEvaluator {
  private struct ScreenSnapshot {
    let frameAppKit: CGRect
    let visibleFrameAppKit: CGRect
    let frameWindowCoordinates: CGRect

    func inset(for edge: DockEdge) -> CGFloat {
      switch edge {
      case .left:
        return max(0, visibleFrameAppKit.minX - frameAppKit.minX)
      case .right:
        return max(0, frameAppKit.maxX - visibleFrameAppKit.maxX)
      case .bottom:
        return max(0, visibleFrameAppKit.minY - frameAppKit.minY)
      }
    }
  }

  private enum DockEdge: String {
    case left
    case right
    case bottom
  }

  private struct DockSpanCandidate {
    let rawBounds: CGRect
    let spanRange: ClosedRange<CGFloat>
    let length: CGFloat
  }

  private struct DockThicknessCacheKey: Equatable {
    let edge: DockEdge
    let screenFrame: CGRect
    let tileSize: CGFloat
    let magnificationEnabled: Bool
    let largeSize: CGFloat
  }

  private let prefsClient: DockPreferencesClient
  var isDockAutoHideEnabled: () -> Bool = { false }

  private var loggedMissingDockFrame: Bool = false
  private var loggedDockCandidates: Bool = false
  private var cachedVisibleDockThickness: CGFloat?
  private var cachedThicknessKey: DockThicknessCacheKey?

  init(prefsClient: DockPreferencesClient) {
    self.prefsClient = prefsClient
  }

  func evaluate() -> DockOverlapDecision? {
    let windows = windowList()
    guard let dockFrame = dockFrame(from: windows) else {
      if !loggedMissingDockFrame {
        DockLogger.log("No dock frame available; skipping smart evaluation")
        loggedMissingDockFrame = true
      }
      return nil
    }
    loggedMissingDockFrame = false

    let overlaps = windowOverlapsDock(
      windows: windows,
      dockFrames: [dockFrame]
    )
    if overlaps {
      return DockOverlapDecision(
        shouldAutoHide: true,
        reason: "windowOverlap:screenVisibleFrame"
      )
    }
    return DockOverlapDecision(
      shouldAutoHide: false,
      reason: "noOverlap:screenVisibleFrame"
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
    let edge = preferredDockEdge()
    let screenSnapshots = currentScreenSnapshots()
    guard let dockScreen = preferredDockScreen(
      for: edge,
      snapshots: screenSnapshots
    ) else {
      return nil
    }

    synchronizeThicknessCache(edge: edge, screen: dockScreen)
    let thickness = dockThickness(for: edge, on: dockScreen)
    let span = dockSpan(
      from: windows,
      edge: edge,
      dockScreen: dockScreen,
      allScreens: screenSnapshots
    )

    if !loggedDockCandidates {
      let visibleInset = dockScreen.inset(for: edge)
      let cachedThickness = cachedVisibleDockThickness ?? -1
      DockLogger.log(
        "Dock geometry: edge=\(edge.rawValue), screen=\(dockScreen.frameWindowCoordinates), visibleInset=\(visibleInset), cachedVisibleThickness=\(cachedThickness), collisionThickness=\(thickness), autoHide=\(isDockAutoHideEnabled())"
      )
      if let span {
        DockLogger.log("Dock span example: \(span.rawBounds)")
      }
      loggedDockCandidates = true
    }

    return dockFrame(
      edge: edge,
      screen: dockScreen,
      thickness: thickness,
      span: span?.spanRange
    )
  }

  private func dockSpan(
    from windows: [[String: Any]],
    edge: DockEdge,
    dockScreen: ScreenSnapshot,
    allScreens: [ScreenSnapshot]
  ) -> DockSpanCandidate? {
    let dockWindows = windows.compactMap {
      window -> (
        CGRect,
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
      let alpha = window[kCGWindowAlpha as String] as? Double ?? 1.0
      let isOnscreen = window[kCGWindowIsOnscreen as String] as? Bool ?? true
      return (bounds, alpha, isOnscreen)
    }

    if dockWindows.isEmpty {
      return nil
    }

    let candidates = dockWindows.compactMap {
      bounds,
      alpha,
      isOnscreen -> (
        DockSpanCandidate
      )? in
      guard isOnscreen,
        alpha > 0
      else { return nil }
      guard
        let screen = nearestScreen(
          for: bounds,
          screens: allScreens.map(\.frameWindowCoordinates)
        ),
        screen.equalTo(dockScreen.frameWindowCoordinates)
      else {
        return nil
      }
      guard let candidateEdge = dockEdge(for: bounds, screen: screen),
        candidateEdge == edge
      else {
        return nil
      }
      let spanRange: ClosedRange<CGFloat>
      let screenLength: CGFloat
      switch edge {
      case .bottom:
        spanRange = bounds.minX...bounds.maxX
        screenLength = screen.width
      case .left, .right:
        spanRange = bounds.minY...bounds.maxY
        screenLength = screen.height
      }

      let length = spanRange.upperBound - spanRange.lowerBound
      if length < 48 {
        return nil
      }
      if length >= screenLength * 0.95 {
        return nil
      }

      return DockSpanCandidate(
        rawBounds: bounds,
        spanRange: spanRange,
        length: length
      )
    }

    if let best = candidates.sorted(by: { lhs, rhs in
      lhs.length > rhs.length
    }).first {
      return best
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
      let effectiveBounds = effectiveWindowBounds(bounds)
      if dockFrames.contains(where: { effectiveBounds.intersects($0) }) {
        return true
      }
    }
    return false
  }

  private func dockFrame(
    edge: DockEdge,
    screen: ScreenSnapshot,
    thickness: CGFloat,
    span: ClosedRange<CGFloat>?
  ) -> CGRect {
    switch edge {
    case .left:
      return CGRect(
        x: screen.frameWindowCoordinates.minX,
        y: span?.lowerBound ?? screen.frameWindowCoordinates.minY,
        width: thickness,
        height: span.map { $0.upperBound - $0.lowerBound }
          ?? screen.frameWindowCoordinates.height
      )
    case .right:
      return CGRect(
        x: screen.frameWindowCoordinates.maxX - thickness,
        y: span?.lowerBound ?? screen.frameWindowCoordinates.minY,
        width: thickness,
        height: span.map { $0.upperBound - $0.lowerBound }
          ?? screen.frameWindowCoordinates.height
      )
    case .bottom:
      return CGRect(
        x: span?.lowerBound ?? screen.frameWindowCoordinates.minX,
        y: screen.frameWindowCoordinates.maxY - thickness,
        width: span.map { $0.upperBound - $0.lowerBound }
          ?? screen.frameWindowCoordinates.width,
        height: thickness
      )
    }
  }

  private func dockThickness(for edge: DockEdge, on screen: ScreenSnapshot)
    -> CGFloat
  {
    let visibleInset = screen.inset(for: edge)
    if !isDockAutoHideEnabled(),
      visibleInset > 0
    {
      cachedVisibleDockThickness = visibleInset
      return visibleInset
    }
    if let cachedVisibleDockThickness,
      cachedVisibleDockThickness > 0
    {
      return cachedVisibleDockThickness
    }
    return expectedVisibleDockThickness()
  }

  private func synchronizeThicknessCache(edge: DockEdge, screen: ScreenSnapshot) {
    let cacheKey = DockThicknessCacheKey(
      edge: edge,
      screenFrame: screen.frameWindowCoordinates,
      tileSize: CGFloat(prefsClient.readTileSize() ?? 64.0),
      magnificationEnabled: prefsClient.readMagnificationEnabled() ?? false,
      largeSize: CGFloat(
        prefsClient.readLargeSize()
          ?? prefsClient.readTileSize()
          ?? 64.0
      )
    )

    if cachedThicknessKey != cacheKey {
      cachedThicknessKey = cacheKey
      cachedVisibleDockThickness = nil
    }
  }

  private func preferredDockEdge() -> DockEdge {
    switch prefsClient.readOrientation() ?? "bottom" {
    case "left":
      return .left
    case "right":
      return .right
    default:
      return .bottom
    }
  }

  private func preferredDockScreen(
    for edge: DockEdge,
    snapshots: [ScreenSnapshot]
  ) -> ScreenSnapshot? {
    if let dockScreen = snapshots
      .map({ (snapshot: $0, inset: $0.inset(for: edge)) })
      .filter({ $0.inset > 0 })
      .max(by: { $0.inset < $1.inset })?.snapshot
    {
      return dockScreen
    }
    return preferredScreenSnapshot(from: snapshots) ?? snapshots.first
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

  private func dockEdge(for bounds: CGRect, screen: CGRect) -> DockEdge? {
    let tolerance: CGFloat = 6
    let leftDistance = abs(bounds.minX - screen.minX)
    let rightDistance = abs(bounds.maxX - screen.maxX)
    let bottomDistance = min(
      abs(bounds.minY - screen.minY),
      abs(bounds.maxY - screen.maxY)
    )

    if bounds.height > bounds.width {
      if leftDistance <= tolerance || rightDistance <= tolerance {
        return leftDistance <= rightDistance ? .left : .right
      }
    }

    if bottomDistance <= tolerance {
      return .bottom
    }
    if leftDistance <= tolerance {
      return .left
    }
    if rightDistance <= tolerance {
      return .right
    }
    return nil
  }

  private func expectedVisibleDockThickness() -> CGFloat {
    let tileSize = CGFloat(prefsClient.readTileSize() ?? 64.0)
    let magnificationEnabled = prefsClient.readMagnificationEnabled() ?? false
    let largeSize = CGFloat(prefsClient.readLargeSize() ?? Double(tileSize))
    let iconSize = magnificationEnabled ? max(tileSize, largeSize) : tileSize

    return min(160.0, max(28.0, iconSize + 12.0))
  }

  private func effectiveWindowBounds(_ bounds: CGRect) -> CGRect {
    let insetX = min(6.0, max(0.0, bounds.width / 20.0))
    let insetY = min(6.0, max(0.0, bounds.height / 20.0))
    let effectiveBounds = bounds.insetBy(dx: insetX, dy: insetY)
    if effectiveBounds.isNull || effectiveBounds.isEmpty {
      return bounds
    }
    return effectiveBounds
  }

  private func currentScreenSnapshots() -> [ScreenSnapshot] {
    if Thread.isMainThread {
      return makeScreenSnapshots()
    }

    var snapshots: [ScreenSnapshot] = []
    DispatchQueue.main.sync {
      snapshots = makeScreenSnapshots()
    }
    return snapshots
  }

  private func makeScreenSnapshots() -> [ScreenSnapshot] {
    guard let main = NSScreen.main ?? NSScreen.screens.first else {
      return []
    }

    let mainMaxY = main.frame.maxY
    return NSScreen.screens.map { screen in
      ScreenSnapshot(
        frameAppKit: screen.frame,
        visibleFrameAppKit: screen.visibleFrame,
        frameWindowCoordinates: convertToWindowCoordinates(
          screen.frame,
          mainMaxY: mainMaxY
        )
      )
    }
  }

  private func preferredScreenSnapshot(from snapshots: [ScreenSnapshot])
    -> ScreenSnapshot?
  {
    guard !snapshots.isEmpty else {
      return nil
    }

    let mouseLocation: CGPoint = if Thread.isMainThread {
      NSEvent.mouseLocation
    } else {
      DispatchQueue.main.sync {
        NSEvent.mouseLocation
      }
    }

    if let pointerScreen = snapshots.first(where: { snapshot in
      snapshot.frameAppKit.contains(mouseLocation)
    }) {
      return pointerScreen
    }

    return snapshots.first
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
