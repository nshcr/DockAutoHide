# DockAutoHide

**Auto-hide the Dock only when a window would cover it.**

DockAutoHide is a tiny macOS menu bar utility that watches for windows overlapping the Dock and flips auto-hide on the fly. It's a simple, focused stopgap for people who want the Dock visible most of the time, but out of the way when a window needs the space — until macOS offers this behavior natively.

## Demo Video

https://github.com/user-attachments/assets/2f6a8341-6084-4d71-a310-c60caff6d269

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

### Option A: Homebrew Tap (Recommended)

```sh
brew tap nshcr/tap
brew install --cask dockautohide
```

- This is the recommended installation method.
- Homebrew installs the app from the dedicated [nshcr/homebrew-tap](https://github.com/nshcr/homebrew-tap) repository.

### Option B: GitHub Releases (DMG, Apple Silicon + Intel)

- Releases are built by [GitHub Actions](https://github.com/nshcr/DockAutoHide/actions/workflows/release.yml) and published as architecture‑specific DMGs.
- Download the DMG that matches your Mac architecture from [GitHub Releases](https://github.com/nshcr/DockAutoHide/releases).
- Open the DMG and drag `DockAutoHide.app` into `/Applications`.

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

DockAutoHide uses two macOS permission areas:

- **Automation (System Events)**: required. The app uses Apple Events to read and toggle Dock auto-hide. Without this permission, DockAutoHide cannot control the Dock.
- **Screen Recording**: optional, but recommended for best Smart Switching behavior. It helps macOS provide more accurate window metadata for overlap detection.

The app does **not** proactively request Screen Recording permission. If you want the best Smart Switching accuracy, add DockAutoHide manually in **System Settings → Privacy & Security → Screen Recording**.

Without Screen Recording permission, DockAutoHide still works in the vast majority of setups:

- Manual Dock auto-hide control still works normally.
- Smart Switching still uses live screen geometry and Dock preferences, but may lose some live Dock span metadata and fall back to the current display context.
- In more complex setups, especially some multi-display arrangements, Smart Switching can be a little less precise.

In short: enabling Screen Recording gives DockAutoHide its best behavior, but leaving it disabled should still be good enough for most everyday use.

## Privacy

DockAutoHide performs all processing locally. It does not collect analytics or transmit data over the network.

## Contributing & Feedback

Contributions of any kind are very welcome. If you try DockAutoHide, I would love to hear your feedback, bug reports, and suggestions. Even small notes about what feels off or where it fails are valuable.

## License

MIT
