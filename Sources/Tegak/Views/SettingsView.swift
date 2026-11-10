import AppKit
import TegakCore

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

    init() {
        super.init(fill: Palette.background)
        buildHeader()
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
        for button in presetButtons {
            let selected = button.tag == state.selectedInterval
            button.title = "\(selected ? "✓ " : "")\(button.tag) menit"
            button.style = selected ? .selected : .secondary
            button.setAccessibilityLabel("\(button.tag) menit\(selected ? ", dipilih" : "")")
        }
    }

    private func buildHeader() {
        place(label("Tegak", size: 30, weight: .semibold), in: self, 32, 22, 300, 40)
        place(label("Pengingat duduk, di sela kesibukanmu.", color: Palette.secondary),
              in: self, 32, 70, 456, 24)
    }

    private func buildCountdown() {
        let surface = SurfaceView(fill: Palette.surface, radius: 16)
        place(surface, in: self, 32, 110, 456, 160)
        captionLabel.alignment = .center
        place(captionLabel, in: surface, 20, 19, 416, 22)
        countdownLabel.font = .monospacedDigitSystemFont(ofSize: 60, weight: .medium)
        countdownLabel.alignment = .center
        countdownLabel.setAccessibilityLabel("Waktu menuju pengingat berikutnya")
        place(countdownLabel, in: surface, 20, 43, 416, 76)
        statusLabel.alignment = .center
        place(statusLabel, in: surface, 20, 125, 416, 20)
    }

    private func buildIntervalControls() {
        place(label("Ingatkan aku setiap", size: 16, weight: .semibold), in: self, 32, 296, 456, 24)
        for (index, minutes) in SettingsViewState.presetMinutes.enumerated() {
            let button = ActionButton("\(minutes) menit")
            button.tag = minutes
            place(button, in: self, 32 + CGFloat(index) * 116, 334, 108, 38)
            presetButtons.append(button)
        }
        place(label("Atau tentukan sendiri", color: Palette.secondary), in: self, 32, 391, 260, 24)
        intervalField.font = .systemFont(ofSize: 15, weight: .medium)
        intervalField.alignment = .center
        intervalField.isBezeled = true
        intervalField.bezelStyle = .roundedBezel
        intervalField.focusRingType = .exterior
        intervalField.setAccessibilityLabel("Interval pengingat dalam menit, 1 sampai 180")
        place(intervalField, in: self, 350, 387, 76, 30)
        place(label("menit", color: Palette.secondary), in: self, 436, 391, 52, 24)
        place(hintLabel, in: self, 32, 432, 456, 36)
    }

    private func buildActions() {
        soundButton.setButtonType(.switch)
        soundButton.title = "Bunyikan suara saat mengingatkan"
        soundButton.font = .systemFont(ofSize: 13)
        place(soundButton, in: self, 32, 481, 456, 26)
        startButton.keyEquivalent = "\r"
        place(startButton, in: self, 32, 533, 264, 44)
        place(previewButton, in: self, 308, 533, 180, 44)
        place(label("Tetap berjalan saat jendela ditutup. Buka dari menu bar.", size: 12, color: Palette.secondary),
              in: self, 32, 599, 456, 24)
    }

    private func configureKeyboardOrder() {
        let controls: [NSView] = presetButtons + [intervalField, soundButton, startButton, previewButton]
        for (index, control) in controls.enumerated() {
            control.nextKeyView = controls[(index + 1) % controls.count]
        }
    }
}
