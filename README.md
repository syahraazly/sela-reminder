
# Sela

**A gentle reminder to sit up straight and stay hydrated.**

Sela is a lightweight, native macOS menu bar app designed to help you build better daily habits through simple posture and hydration reminders.

It runs quietly in the background and displays compact, island-style reminders near the top of your screen.

Built with **Swift** and **AppKit**.

## Features

- **Posture Reminders** — Get reminded to sit up straight throughout the day.
- **Hydration Reminders** — Stay mindful of your daily water intake.
- **Customizable Intervals** — Choose from preset intervals or set your own.
- **Island-Style Notifications** — Receive subtle reminders without disrupting your workflow.
- **Menu Bar Integration** — Easily access settings and control reminders.
- **Snooze & Pause** — Pause reminders or snooze them for five minutes.
- **Optional Sound** — Enable or disable reminder sounds.

> **Note:** Sela uses time-based reminders. It does not track your actual posture, access your camera, or monitor your water consumption.

## Requirements

- macOS 14 (Sonoma) or later
- Apple Silicon or Intel Mac
- Xcode or Swift toolchain (only required when building from source)

## Installation

### Download Sela

1. Go to the [Releases](https://github.com/syahraazly/posture-reminder/releases) page.
2. Download the latest `Sela-*-preview.dmg` file.
3. Double-click the downloaded DMG to open it.
4. Drag **Sela.app** into the **Applications** folder.
5. Open **Sela** from Applications.

> **Important:** Preview builds are not notarized by Apple. macOS may display a security warning when you open Sela for the first time.

### First Launch: "Sela" Not Opened

If macOS displays the message:

**"Apple could not verify Sela is free of malware that may harm your Mac or compromise your privacy."**

This warning may appear because preview builds are ad-hoc signed and have not been notarized by Apple.

It does not necessarily mean the application is corrupted or malicious.

If you trust the build downloaded from this repository, follow these steps.

**Step 1 — Open Sela**

Open `Sela.app` from your Applications folder.

If the **"Sela" Not Opened** warning appears, click **Done** instead of **Move to Trash**.
<img width="510" height="538" alt="image" src="https://github.com/user-attachments/assets/19d9c2c8-48ec-43e4-8a98-71ff50c38ebe" />

**Step 2 — Open Privacy & Security**

1. Open **System Settings**.
2. Navigate to **Privacy & Security**.
3. Scroll down to the **Security** section.
4. Find the message indicating that Sela was blocked.
5. Click **Open Anyway**.
<img width="1002" height="232" alt="image" src="https://github.com/user-attachments/assets/5949a918-1aa3-4b35-9505-4348075f7566" />
<img width="526" height="704" alt="image" src="https://github.com/user-attachments/assets/3cd41ea5-3b08-4428-99c4-612ba38b8d4b" />

**Step 3 — Confirm and Launch**

1. Authenticate with your Mac password or Touch ID if prompted.
2. Click **Open** to confirm.
3. Sela should now launch normally.

You generally only need to complete this process once for the same app version.

If the **Open Anyway** option does not appear, try opening Sela again and return to Privacy & Security.

> **Security Notice:** Only override macOS security warnings for applications you trust. Preview releases have not undergone Apple's notarization process.

For more information, refer to [Apple's official guide](https://support.apple.com/en-us/102445).

## How to Use

**1. Choose a Reminder**

Open Sela and select your preferred reminder:

- **Duduk Tegak** — Posture reminder
- **Minum Air Putih** — Hydration reminder

**2. Set Your Interval**

Choose a preset reminder interval or configure a custom duration.

**3. Start Your Reminder**

Click **Mulai Pengingat** to activate the timer.

Sela will run quietly in the background while you work.

**4. Manage Notifications**

When a reminder appears, you can:

- Acknowledge the reminder.
- Snooze it for five minutes.
- Pause or resume your reminder from the app.

**5. Access from the Menu Bar**

Use the Sela icon in your macOS menu bar to reopen settings or quit the application.

> Closing the settings window does not quit Sela. Reminders continue while the app is running and your Mac is awake.

## Build from Source

### Clone the Repository

```bash
git clone https://github.com/syahraazly/posture-reminder.git
cd posture-reminder
```

### Build the Application

```bash
./build.sh --no-dmg
```

The compiled application will be available at:

```text
dist/Sela.app
```

Launch it using:

```bash
open dist/Sela.app
```

### Generate a DMG

To create a distributable preview DMG:

```bash
zsh scripts/package-dmg.sh --preview
```

The generated files will appear in the `dist/` directory:

```text
dist/
├── Sela.app
├── Sela-0.1.0-universal-preview.dmg
└── Sela-0.1.0-universal-preview.dmg.sha256
```

File names may vary depending on the application version and supported architectures.

### Verify Code Signing

You can verify the application's code signature by running:

```bash
codesign --verify --deep --strict --verbose=2 dist/Sela.app
```

A valid code signature does not mean the preview build has been notarized by Apple.

## Testing

Run the project's test script:

```bash
zsh scripts/test.sh
```

For UI smoke tests:

```bash
zsh scripts/test.sh --ui
```

## Distribution

Preview builds are intended for testing and evaluation.

They are currently:

- Ad-hoc signed.
- Not notarized by Apple.
- Distributed through GitHub Releases.

For a public release without the usual unverified-developer warning, the app should be signed with an Apple **Developer ID Application** certificate and notarized.

## License

See the repository's license file, if provided, for usage and distribution terms.

---

**Sela — Small reminders, better habits.**
