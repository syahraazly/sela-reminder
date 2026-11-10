import AppKit
import TegakCore

@MainActor
final class SmokeTestRunner {
    let coordinator: AppCoordinator
    private let preferences: UserDefaults
    private let clock: SmokeTestClock
    private let isOffscreen: Bool

    init(isOffscreen: Bool) {
        self.isOffscreen = isOffscreen
        guard let preferences = UserDefaults(suiteName: "local.dummy.tegak.smoke") else {
            preconditionFailure("Could not create isolated smoke-test preferences")
        }
        preferences.removePersistentDomain(forName: "local.dummy.tegak.smoke")
        self.preferences = preferences
        let clock = SmokeTestClock()
        self.clock = clock
        let store = UserDefaultsReminderPreferences(defaults: preferences)
        let viewModel = ReminderViewModel(preferences: store, now: { clock.now })
        coordinator = AppCoordinator(viewModel: viewModel, isOffscreen: isOffscreen, isTesting: true)
    }

    func run() {
        let viewModel = coordinator.viewModel
        let settings = coordinator.settingsController
        let island = coordinator.islandController
        let settingsWindow = settings.window
        let settingsSurface = settings.contentView
        let islandSurface = island.contentView
        let panel = island.panel
        let intervalField = settingsSurface.intervalField
        let startButton = settingsSurface.startButton
        let previewButton = settingsSurface.previewButton
        let presetButtons = settingsSurface.presetButtons
        let soundButton = settingsSurface.soundButton
        let islandPrimary = islandSurface.primaryButton
        let islandSecondary = islandSurface.secondaryButton
        var log: [String] = []
        if isOffscreen {
            log.append("INFO: Offscreen AppKit run. Physical display, menu bar, Spaces, and fullscreen placement require an interactive desktop check.")
        }
        var failed = false
        func check(_ condition: @autoclosure () -> Bool, _ message: String) {
            let passed = condition()
            log.append("\(passed ? "PASS" : "FAIL"): \(message)")
            if !passed { failed = true }
        }
        func applyInterval() -> Bool { viewModel.commitInterval(intervalField.stringValue) }

        let output: URL
        if let index = CommandLine.arguments.firstIndex(of: "--smoke-output"),
           CommandLine.arguments.indices.contains(index + 1) {
            output = URL(fileURLWithPath: CommandLine.arguments[index + 1], isDirectory: true)
        } else {
            output = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                .appendingPathComponent("docs/previews", isDirectory: true)
        }
        do {
            try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
            settings.show()
            settingsWindow.displayIfNeeded()
            check(viewModel.state == .idle, "First launch is idle")
            check(viewModel.intervalMinutes == 30, "Default interval is 30 minutes")
            try snapshot(settingsSurface, to: output.appendingPathComponent("settings-idle.png"))
            for button in presetButtons {
                button.performClick(nil)
                check(viewModel.intervalMinutes == button.tag, "Preset \(button.tag) updates interval")
                check(preferences.integer(forKey: "intervalMinutes") == button.tag, "Preset \(button.tag) persists")
            }
            intervalField.stringValue = "abc"
            intervalField.performClick(nil)
            _ = NSApp.sendAction(intervalField.action!, to: intervalField.target, from: intervalField)
            check(settingsSurface.hintLabel.stringValue.contains("Isi angka"), "Invalid input shows useful error")
            check(viewModel.intervalMinutes == 60, "Invalid input preserves interval")
            try snapshot(settingsSurface, to: output.appendingPathComponent("settings-invalid-input.png"))
            for invalid in ["0", "181", "", "1.5", "999999999999999999999"] {
                intervalField.stringValue = invalid
                check(!applyInterval(), "Reject invalid interval '\(invalid)'")
            }
            intervalField.stringValue = "22"
            _ = NSApp.sendAction(intervalField.action!, to: intervalField.target, from: intervalField)
            check(viewModel.intervalMinutes == 22, "Custom interval applies")
            check(preferences.integer(forKey: "intervalMinutes") == 22, "Custom interval persists")
            startButton.performClick(nil)
            check(viewModel.state == .running, "Start button starts timer")
            let deadline = viewModel.nextReminderDate
            previewButton.performClick(nil)
            check(viewModel.isPreviewing, "Preview opens reminder")
            check(viewModel.nextReminderDate == deadline, "Preview preserves scheduled deadline")
            check(panel.frame.height > 100, "Island expands for preview")
            panel.displayIfNeeded()
            try snapshot(islandSurface, to: output.appendingPathComponent("island-preview.png"))
            islandSecondary.performClick(nil)
            check(settings.presentationRequested, "Preview settings button requests settings")
            islandPrimary.performClick(nil)
            check(!viewModel.isPreviewing && viewModel.state == .running, "Close preview preserves running timer")
            check(viewModel.nextReminderDate == deadline, "Closing preview preserves deadline")
            try snapshot(islandSurface, to: output.appendingPathComponent("island-compact.png"))
            startButton.performClick(nil)
            check(viewModel.state == .paused, "Pause button pauses timer")
            try snapshot(settingsSurface, to: output.appendingPathComponent("settings-paused.png"))
            let remaining = viewModel.remaining
            startButton.performClick(nil)
            check(viewModel.state == .running, "Resume button resumes timer")
            check(abs(viewModel.remaining - remaining) < 1, "Resume preserves remaining seconds")
            soundButton.performClick(nil)
            check(viewModel.soundEnabled, "Sound checkbox enables and persists sound")
            soundButton.performClick(nil)
            check(!viewModel.soundEnabled, "Sound checkbox disables sound")
            islandSurface.leftButton.performClick(nil)
            check(panel.frame.height > 100, "Left island wing opens controls")
            islandPrimary.performClick(nil)
            check(viewModel.state == .paused, "Island primary pauses running timer")
            islandSurface.rightButton.performClick(nil)
            check(panel.frame.height > 100, "Right island wing opens controls")
            islandPrimary.performClick(nil)
            check(viewModel.state == .running, "Island primary resumes paused timer")
            island.open()
            islandSecondary.performClick(nil)
            check(settings.presentationRequested, "Island settings button requests settings")
            panel.cancelOperation(nil)
            check(panel.frame.height < 100, "Escape collapses island")
            viewModel.preview()
            panel.cancelOperation(nil)
            check(!viewModel.isPreviewing, "Escape closes preview")
            check(startButton.acceptsFirstResponder && previewButton.acceptsFirstResponder, "Action buttons accept keyboard focus")
            check(startButton.focusRingType == .exterior, "Action buttons keep visible focus rings")
            check(presetButtons.first?.nextKeyView === presetButtons[1], "Tab order follows preset order")
            check(previewButton.nextKeyView === presetButtons.first, "Tab order wraps through controls")
            settingsWindow.makeFirstResponder(presetButtons[0])
            settingsWindow.selectNextKeyView(nil)
            check(settingsWindow.firstResponder === presetButtons[1], "Tab moves focus to next preset")
            settingsWindow.makeFirstResponder(intervalField)
            intervalField.currentEditor()?.doCommand(by: #selector(NSResponder.insertTab(_:)))
            check(settingsWindow.firstResponder === soundButton, "Tab reaches sound checkbox after interval input")
            settingsWindow.selectNextKeyView(nil)
            check(settingsWindow.firstResponder === startButton, "Tab reaches primary action after sound checkbox")
            if let enter = NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: [],
                timestamp: 0, windowNumber: settingsWindow.windowNumber, context: nil,
                characters: "\r", charactersIgnoringModifiers: "\r", isARepeat: false, keyCode: 36) {
                check(startButton.performKeyEquivalent(with: enter), "Enter activates primary action")
                check(viewModel.state == .paused, "Keyboard activation pauses timer")
                startButton.performClick(nil)
            } else { check(false, "Could not create keyboard event") }
            intervalField.stringValue = "30"
            _ = applyInterval()
            settingsWindow.makeFirstResponder(startButton)
            settingsWindow.appearance = NSAppearance(named: .aqua)
            settingsSurface.needsDisplay = true
            settingsWindow.displayIfNeeded()
            try snapshot(settingsSurface, to: output.appendingPathComponent("settings-light.png"))
            settingsWindow.appearance = NSAppearance(named: .darkAqua)
            settingsSurface.needsDisplay = true
            settingsWindow.displayIfNeeded()
            try snapshot(settingsSurface, to: output.appendingPathComponent("settings-dark.png"))
            settingsWindow.appearance = nil
            settingsWindow.cancelOperation(nil)
            check(!settings.presentationRequested, "Escape dismisses settings")
            check(viewModel.state == .running, "Closing settings leaves timer running")
            settings.show()
            check(settings.presentationRequested, "Reopen requests settings")
            log.append(contentsOf: try verifyReminderControls(output: output))
            check(!log.contains(where: { $0.hasPrefix("FAIL") }), "All real reminder controls pass")
        } catch {
            failed = true
            log.append("FAIL: \(error)")
        }
        let result = log.joined(separator: "\n") + "\n"
        print(result)
        do { try result.write(to: output.appendingPathComponent("smoke-test.txt"), atomically: true, encoding: .utf8) }
        catch { failed = true; print("FAIL: Could not write smoke-test report: \(error)") }
        preferences.removePersistentDomain(forName: "local.dummy.tegak.smoke")
        fflush(nil)
        exit(failed ? 1 : 0)
    }

    private func snapshot(_ view: NSView, to url: URL) throws {
        view.layoutSubtreeIfNeeded()
        view.displayIfNeeded()
        guard let bitmap = view.bitmapImageRepForCachingDisplay(in: view.bounds),
              let data = render(view, into: bitmap) else {
            throw NSError(domain: "Tegak.Smoke", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Could not render view as PNG"])
        }
        try data.write(to: url)
    }

    private func render(_ view: NSView, into bitmap: NSBitmapImageRep) -> Data? {
        view.cacheDisplay(in: view.bounds, to: bitmap)
        return bitmap.representation(using: .png, properties: [:])
    }

    private func verifyReminderControls(output: URL) throws -> [String] {
        let viewModel = coordinator.viewModel
        let island = coordinator.islandController
        viewModel.commitInterval("1")
        var results: [String] = []
        func check(_ condition: Bool, _ message: String) {
            results.append("\(condition ? "PASS" : "FAIL"): \(message)")
        }
        clock.advance(seconds: 60)
        viewModel.tick()
        check(viewModel.state == .reminding, "Elapsed timer opens real reminder")
        check(island.contentView.primaryButton.title == "Sudah tegak", "Real reminder exposes acknowledgement")
        island.panel.displayIfNeeded()
        try snapshot(island.contentView, to: output.appendingPathComponent("island-reminder.png"))
        island.contentView.secondaryButton.performClick(nil)
        check(viewModel.state == .running && viewModel.remaining == 300, "Snooze button schedules five minutes")
        clock.advance(seconds: 300)
        viewModel.tick()
        island.contentView.primaryButton.performClick(nil)
        check(viewModel.state == .running && viewModel.remaining == 60, "Acknowledgement restarts chosen interval")
        clock.advance(seconds: 60)
        viewModel.tick()
        coordinator.settingsController.contentView.startButton.performClick(nil)
        check(viewModel.state == .running && viewModel.remaining == 60, "Settings acknowledges reminder")
        clock.advance(seconds: 60)
        viewModel.tick()
        island.panel.cancelOperation(nil)
        check(viewModel.state == .running && viewModel.remaining == 300, "Escape snoozes real reminder")
        return results
    }
}

@MainActor
private final class SmokeTestClock {
    var now = Date(timeIntervalSince1970: 1_000)
    func advance(seconds: TimeInterval) { now = now.addingTimeInterval(seconds) }
}
