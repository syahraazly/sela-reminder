import AppKit
import TegakCore

extension AppDelegate {
    func runSmokeTests() {
        var log: [String] = []
        if isOffscreenTesting {
            log.append("INFO: Offscreen AppKit run. Physical display, menu bar, Spaces, and fullscreen placement require an interactive desktop check.")
        }
        var failed = false
        func check(_ condition: @autoclosure () -> Bool, _ message: String) {
            let passed = condition()
            log.append("\(passed ? "PASS" : "FAIL"): \(message)")
            if !passed { failed = true }
        }

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
            showSettings(nil)
            settingsWindow.displayIfNeeded()
            check(engine.state == .idle, "First launch is idle")
            check(engine.intervalMinutes == 30, "Default interval is 30 minutes")
            try snapshot(settingsSurface, to: output.appendingPathComponent("settings-idle.png"))

            for button in presetButtons {
                button.performClick(nil)
                check(engine.intervalMinutes == button.tag, "Preset \(button.tag) updates interval")
                check(preferences.integer(forKey: "intervalMinutes") == button.tag,
                      "Preset \(button.tag) persists")
            }
            intervalField.stringValue = "abc"
            intervalField.performClick(nil)
            _ = NSApp.sendAction(intervalField.action!, to: intervalField.target, from: intervalField)
            check(hintLabel.stringValue.contains("Isi angka"), "Invalid input shows useful error")
            check(engine.intervalMinutes == 60, "Invalid input preserves interval")
            try snapshot(settingsSurface, to: output.appendingPathComponent("settings-invalid-input.png"))
            for invalid in ["0", "181", "", "1.5", "999999999999999999999"] {
                intervalField.stringValue = invalid
                check(!commitInterval(), "Reject invalid interval '\(invalid)'")
            }
            intervalField.stringValue = "22"
            _ = NSApp.sendAction(intervalField.action!, to: intervalField.target, from: intervalField)
            check(engine.intervalMinutes == 22, "Custom interval applies")
            check(preferences.integer(forKey: "intervalMinutes") == 22, "Custom interval persists")
            startButton.performClick(nil)
            check(engine.state == .running, "Start button starts timer")
            let deadline = engine.deadline
            previewButton.performClick(nil)
            check(engine.isPreviewing, "Preview opens reminder")
            check(engine.deadline == deadline, "Preview preserves scheduled deadline")
            check(panel.frame.height > 100, "Island expands for preview")
            panel.displayIfNeeded()
            try snapshot(islandSurface, to: output.appendingPathComponent("island-preview.png"))
            islandSecondary.performClick(nil)
            check(settingsPresentationRequested, "Preview settings button requests settings")
            islandPrimary.performClick(nil)
            check(!engine.isPreviewing && engine.state == .running, "Close preview preserves running timer")
            check(engine.deadline == deadline, "Closing preview preserves deadline")
            try snapshot(islandSurface, to: output.appendingPathComponent("island-compact.png"))

            startButton.performClick(nil)
            check(engine.state == .paused, "Pause button pauses timer")
            try snapshot(settingsSurface, to: output.appendingPathComponent("settings-paused.png"))
            let remaining = engine.remaining
            startButton.performClick(nil)
            check(engine.state == .running, "Resume button resumes timer")
            check(abs(engine.remaining - remaining) < 1, "Resume preserves remaining seconds")
            soundButton.performClick(nil)
            check(soundEnabled, "Sound checkbox enables and persists sound")
            soundButton.performClick(nil)
            check(!soundEnabled, "Sound checkbox disables sound")

            islandLeft.performClick(nil)
            check(panel.frame.height > 100, "Left island wing opens controls")
            islandPrimary.performClick(nil)
            check(engine.state == .paused, "Island primary pauses running timer")
            islandRight.performClick(nil)
            check(panel.frame.height > 100, "Right island wing opens controls")
            islandPrimary.performClick(nil)
            check(engine.state == .running, "Island primary resumes paused timer")
            openIsland(nil)
            islandSecondary.performClick(nil)
            check(settingsPresentationRequested, "Island settings button requests settings")
            panel.cancelOperation(nil)
            check(panel.frame.height < 100, "Escape collapses island")
            preview(nil)
            panel.cancelOperation(nil)
            check(!engine.isPreviewing, "Escape closes preview")

            check(startButton.acceptsFirstResponder && previewButton.acceptsFirstResponder,
                  "Action buttons accept keyboard focus")
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
                check(engine.state == .paused, "Keyboard activation pauses timer")
                startButton.performClick(nil)
            } else { check(false, "Could not create keyboard event") }

            intervalField.stringValue = "30"
            _ = commitInterval()
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
            check(!settingsPresentationRequested, "Escape dismisses settings")
            check(engine.state == .running, "Closing settings leaves timer running")
            _ = applicationShouldHandleReopen(NSApp, hasVisibleWindows: false)
            check(settingsPresentationRequested, "Reopen requests settings")

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
        guard let bitmap = view.bitmapImageRepForCachingDisplay(in: view.bounds) else {
            throw NSError(domain: "Tegak.Smoke", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Could not render view"])
        }
        view.cacheDisplay(in: view.bounds, to: bitmap)
        guard let data = bitmap.representation(using: .png, properties: [:]) else {
            throw NSError(domain: "Tegak.Smoke", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "Could not encode PNG"])
        }
        try data.write(to: url)
    }

    private func verifyReminderControls(output: URL) throws -> [String] {
        // A separate clock drives the real UI handlers without waiting for a one-minute interval.
        var now = Date(timeIntervalSince1970: 1_000)
        let original = engine
        engine.onChange = nil
        engine = ReminderEngine(intervalMinutes: 1, now: { now })
        engine.onChange = { [weak self] in self?.refresh() }
        intervalField.stringValue = "1"
        defer {
            engine = original
            engine.onChange = { [weak self] in self?.refresh() }
            refresh()
        }
        var results: [String] = []
        func check(_ condition: Bool, _ message: String) {
            results.append("\(condition ? "PASS" : "FAIL"): \(message)")
        }
        engine.start()
        now = now.addingTimeInterval(60)
        engine.tick()
        check(engine.state == .reminding, "Elapsed timer opens real reminder")
        check(islandPrimary.title == "Sudah tegak", "Real reminder exposes acknowledgement")
        panel.displayIfNeeded()
        try snapshot(islandSurface, to: output.appendingPathComponent("island-reminder.png"))
        islandSecondary.performClick(nil)
        check(engine.state == .running && engine.remaining == 300, "Snooze button schedules five minutes")
        now = now.addingTimeInterval(300)
        engine.tick()
        islandPrimary.performClick(nil)
        check(engine.state == .running && engine.remaining == 60, "Acknowledgement restarts chosen interval")
        now = now.addingTimeInterval(60)
        engine.tick()
        startButton.performClick(nil)
        check(engine.state == .running && engine.remaining == 60, "Settings acknowledges reminder")
        now = now.addingTimeInterval(TimeInterval(engine.intervalMinutes * 60))
        engine.tick()
        panel.cancelOperation(nil)
        check(engine.state == .running && engine.remaining == 300, "Escape snoozes real reminder")
        return results
    }
}
