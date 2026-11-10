import AppKit
import SelaCore

@MainActor
final class SettingsView: SurfaceView {
    let countdownLabel = label("30:00", size: 60, weight: .medium)
    let captionLabel = label("Pengingat berikutnya", color: Palette.secondary)
    let statusLabel = label("Belum dimulai", size: 12, color: Palette.secondary)
    let intervalField = NSTextField(string: "30")
    let hintLabel = label("1–180 menit. Perubahan mengulang hitungan timer.", size: 12, color: Palette.secondary)
    let soundButton = KeyboardCheckbox(frame: .zero)
    let startButton = ActionButton("Mulai pengingat", style: .primary)
    let previewButton = ActionButton("Coba pengingat")
    private(set) var presetButtons: [ActionButton] = []
    private(set) var reminderKindButtons: [ActionButton] = []

    init() {
        super.init(fill: Palette.background)
        buildHeader()
        buildReminderKindControls()
        buildCountdown()
        buildIntervalControls()
        buildActions()
        configureKeyboardOrder()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }

    func render(_ state: SettingsViewState) {
        countdownLabel.stringValue = state.countdown
        captionLabel.stringValue = state.caption
        statusLabel.stringValue = state.status
        startButton.title = state.primaryTitle
        startButton.needsDisplay = true
        hintLabel.stringValue = state.hint
        hintLabel.textColor = state.hasInputError ? Palette.adaptive(0xA63E17, 0xF1A379) : Palette.secondary
        soundButton.state = state.soundEnabled ? .on : .off
        if !state.isEditingInterval { intervalField.stringValue = state.intervalInput }
        for (button, option) in zip(reminderKindButtons, SettingsViewState.reminderOptions) {
            let selected = option.kind == state.selectedReminderKind
            button.title = "\(selected ? "✓ " : "")\(option.title)"
            button.style = selected ? .selected : .secondary
            button.setAccessibilityLabel("\(option.title)\(selected ? ", dipilih" : "")")
        }
        for button in presetButtons {
            let selected = button.tag == state.selectedInterval
            button.title = "\(selected ? "✓ " : "")\(button.tag) menit"
            button.style = selected ? .selected : .secondary
            button.setAccessibilityLabel("\(button.tag) menit\(selected ? ", dipilih" : "")")
        }
    }

    private func buildHeader() {
        place(label(AppIdentity.name, size: 30, weight: .semibold), in: self, 32, 22, 300, 40)
        place(label("Pengingat harian, di sela kesibukanmu.", color: Palette.secondary),
              in: self, 32, 70, 456, 24)
    }

    private func buildReminderKindControls() {
        place(label("Ingatkan untuk", weight: .semibold), in: self, 32, 111, 140, 24)
        for (index, option) in SettingsViewState.reminderOptions.enumerated() {
            let button = ActionButton(option.title)
            button.identifier = NSUserInterfaceItemIdentifier(option.kind.rawValue)
            place(button, in: self, 184 + CGFloat(index) * 158, 105, 146, 36)
            reminderKindButtons.append(button)
        }
    }

    private func buildCountdown() {
        let surface = SurfaceView(fill: Palette.surface, radius: 16)
        place(surface, in: self, 32, 158, 456, 132)
        captionLabel.alignment = .center
        place(captionLabel, in: surface, 20, 12, 416, 20)
        countdownLabel.font = .monospacedDigitSystemFont(ofSize: 56, weight: .medium)
        countdownLabel.alignment = .center
        countdownLabel.setAccessibilityLabel("Waktu menuju pengingat berikutnya")
        place(countdownLabel, in: surface, 20, 34, 416, 70)
        statusLabel.alignment = .center
        place(statusLabel, in: surface, 20, 107, 416, 20)
    }

    private func buildIntervalControls() {
        place(label("Ingatkan aku setiap", size: 16, weight: .semibold), in: self, 32, 310, 456, 24)
        for (index, minutes) in SettingsViewState.presetMinutes.enumerated() {
            let button = ActionButton("\(minutes) menit")
            button.tag = minutes
            place(button, in: self, 32 + CGFloat(index) * 116, 346, 108, 38)
            presetButtons.append(button)
        }
        place(label("Atau tentukan sendiri", color: Palette.secondary), in: self, 32, 403, 260, 24)
        intervalField.font = .systemFont(ofSize: 15, weight: .medium)
        intervalField.alignment = .center
        intervalField.isBezeled = true
        intervalField.bezelStyle = .roundedBezel
        intervalField.focusRingType = .exterior
        intervalField.setAccessibilityLabel("Interval pengingat dalam menit, 1 sampai 180")
        place(intervalField, in: self, 350, 399, 76, 30)
        place(label("menit", color: Palette.secondary), in: self, 436, 403, 52, 24)
        place(hintLabel, in: self, 32, 440, 456, 36)
    }

    private func buildActions() {
        soundButton.setButtonType(.switch)
        soundButton.title = "Bunyikan suara saat mengingatkan"
        soundButton.font = .systemFont(ofSize: 13)
        place(soundButton, in: self, 32, 487, 456, 26)
        startButton.keyEquivalent = "\r"
        place(startButton, in: self, 32, 539, 264, 44)
        place(previewButton, in: self, 308, 539, 180, 44)
        place(label("Tetap berjalan saat jendela ditutup. Buka dari menu bar.", size: 12, color: Palette.secondary),
              in: self, 32, 601, 456, 24)
    }

    private func configureKeyboardOrder() {
        let controls: [NSView] = reminderKindButtons + presetButtons + [intervalField, soundButton, startButton, previewButton]
        for (index, control) in controls.enumerated() {
            control.nextKeyView = controls[(index + 1) % controls.count]
        }
    }
}
