# DockAutoHide

**Auto-hide the Dock only when a window would cover it.**

DockAutoHide is a tiny macOS menu bar utility that watches for windows overlapping the Dock and flips auto-hide on the fly. It's a simple, focused stopgap for people who want the Dock visible most of the time, but out of the way when a window needs the space — until macOS offers this behavior natively.

## Demo Video

## Why You Might Want This

- You keep the Dock visible for quick app switching, but hate losing content space when windows touch the screen edge.
- You don't want to manually toggle auto-hide all day.
- You want a tiny, menu bar–only helper that quietly handles it for you.

## Key Features

- **Smart Switching**: automatically toggles Dock auto-hide based on window overlap.
- **Manual override**: a one-click menu item to force Dock auto-hide on/off.
- **Menu bar only**: no Dock icon, no window.
- **Launch at Login** support.
- **Local-only** behavior with no network access.

## Experimental Status

This is a simple tool but still in an early, experimental stage. It has not been tested across enough real-world setups, and some interactions may feel rough or inconsistent.

That said, it is fully usable: the developer already runs it daily. The goal is to provide a practical, lightweight alternative until Apple ships an official feature like this.

Feedback is hugely appreciated — especially reports of edge cases.

## Installation

**Notarization note**: I couldn't complete Apple notarization because identity verification failed during Apple Developer Program enrollment. The CI is prepared to sign and notarize builds, but until notarization is finished all downloaded builds will be treated as unsafe by macOS. If that happens you can allow the app via **System Settings → Privacy & Security → Open Anyway**.

If you'd prefer to avoid that altogether, building from source is the safest option. For advanced users who understand the risks, the quarantine attribute can be removed (for example with `xattr -rd com.apple.quarantine /Applications/DockAutoHide.app`), but please only do this if you know what it means.

### Option A: GitHub Releases (DMG, Apple Silicon + Intel)

- Releases are built by [GitHub Actions](https://github.com/nshcr/DockAutoHide/actions/workflows/release.yml) and published as architecture‑specific DMGs.
- Download the DMG that matches your Mac architecture from [GitHub Releases](https://github.com/nshcr/DockAutoHide/releases).
- Open the DMG and drag `DockAutoHide.app` into `/Applications`.
- Launch the app and grant permissions when prompted.

### Option B: Homebrew (coming soon)

```sh
brew install --cask dockautohide
```

### Option C: Build from source

1. Open `DockAutoHide.xcodeproj` in Xcode.
2. Select the `DockAutoHide` scheme.
3. Build and run.

## Usage

- Click the menu bar icon to open the menu.
- **Smart Switching** toggles automatic behavior on/off.
- **Dock Auto-Hide** manually toggles the Dock (disabled while Smart Switching is on).
- **Status** shows the current Dock auto-hide state or authorization status.
- **Request System Events Permission** appears if automation permission is missing.
- **Launch at Login** toggles startup behavior.
- **Quit** exits the app.

## System Requirements

- macOS 13.5+ (deployment target set in the Xcode project).
- Apple Silicon or Intel Mac.

## Permissions

DockAutoHide needs the following permissions to function correctly:

- **Automation (System Events)**: required to read and toggle Dock auto-hide via Apple Events.
- **Screen Recording**: recommended for accurate window overlap detection in Smart Switching.

The app does **not** proactively request Screen Recording permission. If you want the most accurate Smart Switching, add DockAutoHide manually in **System Settings → Privacy & Security → Screen Recording**.

Without Screen Recording permission, the app still works, but Smart Switching may fall back to Dock preference heuristics and be less accurate.

## Privacy

DockAutoHide performs all processing locally. It does not collect analytics or transmit data over the network.

## Contributing & Feedback

Contributions of any kind are very welcome. If you try DockAutoHide, I would love to hear your feedback, bug reports, and suggestions. Even small notes about what feels off or where it fails are valuable.

## License

MIT
