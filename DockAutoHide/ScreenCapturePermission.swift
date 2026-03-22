import CoreGraphics

enum ScreenCapturePermission {
  static var hasAccess: Bool {
    CGPreflightScreenCaptureAccess()
  }
}
