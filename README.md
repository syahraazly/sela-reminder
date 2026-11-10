# Sela

**A gentle reminder to sit up straight and stay hydrated.**

Sela is a lightweight, native macOS menu bar app that helps you remember to check your posture or drink water during the day. It runs quietly in the background and shows a small reminder near the top of your screen when it's time.

Built with **Swift** and **AppKit**.

## Features

- **Posture and water reminders** — Choose to be reminded to sit up straight or drink water.
- **Flexible intervals** — Use a 15, 30, 45, or 60-minute preset, or set a custom interval from 1 to 180 minutes.
- **Island-style reminders** — See reminders in a compact overlay near the top of your screen, including on Macs without a notch.
- **Simple controls** — Start, pause, resume, acknowledge, or snooze a reminder for five minutes.
- **Menu bar access** — Keep the app running without leaving a window open.
- **Optional sound** — Turn reminder sounds on or off; your preferences are saved locally.

> Sela is a timer-based reminder app. It does not detect your posture or use your camera. Only one reminder type is active at a time.

## Requirements

- macOS 14 (Sonoma) or later
- For building from source: Git and Swift 6+ (via Xcode or Xcode Command Line Tools)

## Installation

### Download the app

Check the [Releases page](https://github.com/syahraazly/posture-reminder/releases) for a downloadable `Sela.dmg`.

Once a DMG is available:

1. Download and open `Sela.dmg`.
2. Drag **Sela.app** into **Applications**.
3. Open **Sela** from Applications.

**Note:** Preview builds are ad-hoc signed and are not notarized by Apple. macOS may show a security warning. Only open a build if you trust its source; consult [Apple's guidance](https://support.apple.com/guide/mac-help/open-a-mac-app-from-an-unidentified-developer-mh40616/mac) if needed.

**No DMG on the Releases page yet?** You can build the app locally using the steps below.

### Build from source

```bash
git clone https://github.com/syahraazly/posture-reminder.git
cd posture-reminder
./build.sh --no-dmg
open dist/Sela.app
```

If Swift isn't installed, first install Xcode or run `xcode-select --install` to install the Command Line Tools.

The built app will be located at `dist/Sela.app`. You can also double-click `Jalankan Sela.command` from Finder to build and launch it.

## How to use

1. Open **Sela** and choose **Duduk tegak** (sit up straight) or **Minum air putih** (drink water).
2. Select a reminder interval or enter your own.
3. Click **Mulai pengingat** to start the timer.
4. When a reminder appears, acknowledge it to begin the next interval or snooze it for five minutes.
5. Use the menu bar icon to reopen settings or quit Sela.

Closing the settings window does not quit the app. Reminders run while Sela is open and your Mac is awake.

## For developers

### Build a distributable DMG

From the repository root, run:

```bash
./build.sh
```

This creates:

```text
dist/
├── Sela.app
├── Sela.dmg
└── Sela.dmg.sha256
```

On macOS, you can also double-click `Buat DMG.command` in Finder. The `dist/` directory is ignored by Git; distribute the DMG through GitHub Releases rather than committing it to the repository.

### Run tests

```bash
zsh scripts/test.sh
```

For UI smoke tests:

```bash
zsh scripts/test.sh --ui
```

### Publishing a preview release

You can attach `dist/Sela.dmg` to a new [GitHub Release](https://github.com/syahraazly/posture-reminder/releases/new), or use **Actions → Publish DMG preview → Run workflow** to build and publish a preview release.

For architecture, build details, and distribution notes, see the [`docs/`](docs/) directory.

---

**Made for small, mindful breaks throughout your day.**
