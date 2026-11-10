import AppKit
import TegakCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSTextFieldDelegate {
    let isTesting = CommandLine.arguments.contains("--smoke-test")
    var isOffscreenTesting: Bool { isTesting && NSScreen.screens.isEmpty }
    private(set) var settingsPresentationRequested = false
    lazy var preferences: UserDefaults = isTesting
        ? UserDefaults(suiteName: "local.dummy.tegak.smoke")! : .standard
    lazy var engine = ReminderEngine(intervalMinutes: preferences.object(forKey: "intervalMinutes") as? Int ?? 30)

    private(set) var settingsWindow: SettingsWindow!
    private(set) var panel: IslandPanel!
    private(set) var settingsSurface: SurfaceView!
    private(set) var islandSurface: IslandSurface!
    private(set) var startButton: ActionButton!
    private(set) var previewButton: ActionButton!
    private(set) var presetButtons: [ActionButton] = []
    private(set) var intervalField: NSTextField!
    private(set) var soundButton: NSButton!
    private(set) var islandPrimary: ActionButton!
    private(set) var islandSecondary: ActionButton!
    private(set) var islandLeft: ActionButton!
    private(set) var islandRight: ActionButton!
    private(set) var countdownLabel: NSTextField!
    private(set) var hintLabel: NSTextField!

    private var stateLabel: NSTextField!
    private var countdownCaption: NSTextField!
    private var islandHeading: NSTextField!
    private var islandSubtitle: NSTextField!
    private var statusItem: NSStatusItem!
    private var menuStatus: NSMenuItem!
    private var menuToggle: NSMenuItem!
    private var timer: Timer?
    private var userExpanded = false
    private var lastExpanded: Bool?
    private var topBand: CGFloat = 34
    private var compactWidth: CGFloat = 350
    private var expandedWidth: CGFloat = 480
    private var customInputError = false
    private var isEditingInterval = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        if isTesting { preferences.removePersistentDomain(forName: "local.dummy.tegak.smoke") }
        createSettings()
        createIsland()
        createMenus()
        engine.onChange = { [weak self] in self?.refresh() }
        engine.onReminder = { [weak self] in
            guard let self, self.soundEnabled, !self.isTesting else { return }
            NSSound(named: "Pop")?.play()
        }
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(didWake),
            name: NSWorkspace.didWakeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(screenChanged),
            name: NSApplication.didChangeScreenParametersNotification, object: nil)
        refresh()
        if isTesting {
            if isOffscreenTesting { runSmokeTests() }
            else { DispatchQueue.main.async { [weak self] in self?.runSmokeTests() } }
        } else {
            timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
                MainActor.assumeIsolated { self?.engine.tick() }
            }
            timer?.tolerance = 0.15
            RunLoop.main.add(timer!, forMode: .common)
            showSettings(nil)
        }
    }

    var soundEnabled: Bool { preferences.object(forKey: "soundEnabled") as? Bool ?? false }

    private func createSettings() {
        settingsWindow = SettingsWindow(contentRect: NSRect(x: 0, y: 0, width: 520, height: 650),
            styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
        settingsWindow.title = "Tegak"
        settingsWindow.titlebarAppearsTransparent = true
        settingsWindow.backgroundColor = Palette.background
        settingsWindow.isReleasedWhenClosed = false
        settingsWindow.center()
        settingsWindow.onEscape = { [weak self] in self?.hideSettings() }
        settingsSurface = SurfaceView(fill: Palette.background)
        settingsWindow.contentView = settingsSurface

        place(label("Tegak", size: 30, weight: .semibold), in: settingsSurface, 32, 22, 300, 40)
        place(label("Pengingat duduk, di sela kesibukanmu.", color: Palette.secondary),
              in: settingsSurface, 32, 70, 456, 24)

        let timerSurface = SurfaceView(fill: Palette.surface, radius: 16)
        place(timerSurface, in: settingsSurface, 32, 110, 456, 160)
        countdownCaption = label("Pengingat berikutnya", color: Palette.secondary)
        countdownCaption.alignment = .center
        place(countdownCaption, in: timerSurface, 20, 19, 416, 22)
        countdownLabel = label("30:00", size: 60, weight: .medium)
        countdownLabel.font = .monospacedDigitSystemFont(ofSize: 60, weight: .medium)
        countdownLabel.alignment = .center
        countdownLabel.setAccessibilityLabel("Waktu menuju pengingat berikutnya")
        place(countdownLabel, in: timerSurface, 20, 43, 416, 76)
        stateLabel = label("Belum dimulai", size: 12, color: Palette.secondary)
        stateLabel.alignment = .center
        place(stateLabel, in: timerSurface, 20, 125, 416, 20)

        place(label("Ingatkan aku setiap", size: 16, weight: .semibold),
              in: settingsSurface, 32, 296, 456, 24)
        for (index, minutes) in [15, 30, 45, 60].enumerated() {
            let button = ActionButton("\(minutes) menit", target: self, action: #selector(selectPreset(_:)))
            button.tag = minutes
            place(button, in: settingsSurface, 32 + CGFloat(index) * 116, 334, 108, 38)
            presetButtons.append(button)
        }

        place(label("Atau tentukan sendiri", color: Palette.secondary),
              in: settingsSurface, 32, 391, 260, 24)
        intervalField = NSTextField(string: "\(engine.intervalMinutes)")
        intervalField.font = .systemFont(ofSize: 15, weight: .medium)
        intervalField.alignment = .center
        intervalField.isBezeled = true
        intervalField.bezelStyle = .roundedBezel
        intervalField.focusRingType = .exterior
        intervalField.delegate = self
        intervalField.target = self
        intervalField.action = #selector(applyCustomInterval(_:))
        intervalField.setAccessibilityLabel("Interval pengingat dalam menit, 1 sampai 180")
        place(intervalField, in: settingsSurface, 350, 387, 76, 30)
        place(label("menit", color: Palette.secondary), in: settingsSurface, 436, 391, 52, 24)
        hintLabel = label("1–180 menit. Perubahan mengulang hitungan timer.", size: 12, color: Palette.secondary)
        place(hintLabel, in: settingsSurface, 32, 432, 456, 36)

        soundButton = KeyboardCheckbox(frame: .zero)
        soundButton.setButtonType(.switch)
        soundButton.title = "Bunyikan suara saat mengingatkan"
        soundButton.target = self
        soundButton.action = #selector(toggleSound(_:))
        soundButton.font = .systemFont(ofSize: 13)
        soundButton.state = soundEnabled ? .on : .off
        place(soundButton, in: settingsSurface, 32, 481, 456, 26)

        startButton = ActionButton("Mulai pengingat", style: .primary, target: self, action: #selector(toggleTimer(_:)))
        startButton.keyEquivalent = "\r"
        place(startButton, in: settingsSurface, 32, 533, 264, 44)
        previewButton = ActionButton("Coba pengingat", target: self, action: #selector(preview(_:)))
        place(previewButton, in: settingsSurface, 308, 533, 180, 44)
        place(label("Tetap berjalan saat jendela ditutup. Buka dari menu bar.", size: 12, color: Palette.secondary),
              in: settingsSurface, 32, 599, 456, 24)

        let controls: [NSView] = presetButtons + [intervalField, soundButton, startButton, previewButton]
        for (index, control) in controls.enumerated() {
            control.nextKeyView = controls[(index + 1) % controls.count]
        }
        settingsWindow.initialFirstResponder = startButton
    }

    private func createIsland() {
        panel = IslandPanel(contentRect: NSRect(x: 0, y: 0, width: 480, height: 170),
            styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = NSWindow.Level(rawValue: NSWindow.Level.statusBar.rawValue + 1)
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.isReleasedWhenClosed = false
        panel.onEscape = { [weak self] in self?.closeIsland() }
        islandSurface = IslandSurface(frame: .zero)
        panel.contentView = islandSurface

        islandLeft = ActionButton("Tegak", style: .bare, target: self, action: #selector(toggleIsland(_:)))
        islandLeft.font = .systemFont(ofSize: 11, weight: .semibold)
        islandLeft.setAccessibilityLabel("Buka atau tutup island Tegak")
        islandSurface.addSubview(islandLeft)
        islandRight = ActionButton("30:00", style: .bare, target: self, action: #selector(toggleIsland(_:)))
        islandRight.font = .monospacedDigitSystemFont(ofSize: 11, weight: .medium)
        islandRight.setAccessibilityLabel("Buka status pengingat")
        islandSurface.addSubview(islandRight)
        islandHeading = label("Yuk, duduk lebih tegak.", size: 21, weight: .semibold, color: .white)
        islandSurface.addSubview(islandHeading)
        islandSubtitle = label("Rilekskan bahu dan sesuaikan posisi dudukmu.", size: 12, color: Palette.onBlackSecondary)
        islandSurface.addSubview(islandSubtitle)
        islandPrimary = ActionButton("Sudah tegak", style: .islandPrimary, target: self,
                                     action: #selector(islandPrimaryAction(_:)))
        islandSurface.addSubview(islandPrimary)
        islandSecondary = ActionButton("Tunda 5 menit", style: .islandSecondary, target: self,
                                       action: #selector(islandSecondaryAction(_:)))
        islandSurface.addSubview(islandSecondary)
        islandLeft.nextKeyView = islandRight
        islandRight.nextKeyView = islandPrimary
        islandPrimary.nextKeyView = islandSecondary
        islandSecondary.nextKeyView = islandLeft
    }

    private func createMenus() {
        if !isOffscreenTesting {
            statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
            if let image = NSImage(systemSymbolName: "figure.seated.side", accessibilityDescription: "Tegak, pengingat duduk") {
                image.isTemplate = true
                statusItem.button?.image = image
            } else {
                statusItem.button?.title = "T"
            }
            statusItem.button?.toolTip = "Tegak · Pengingat duduk"
        }
        let menu = NSMenu()
        menuStatus = NSMenuItem(title: "Tegak · Belum dimulai", action: nil, keyEquivalent: "")
        menu.addItem(menuStatus)
        menu.addItem(.separator())
        menuToggle = menuItem("Mulai pengingat", #selector(toggleTimer(_:)), "s")
        menu.addItem(menuToggle)
        menu.addItem(menuItem("Coba pengingat", #selector(preview(_:)), "p"))
        menu.addItem(menuItem("Buka island", #selector(openIsland(_:)), "i"))
        menu.addItem(.separator())
        menu.addItem(menuItem("Pengaturan…", #selector(showSettings(_:)), ","))
        menu.addItem(menuItem("Keluar dari Tegak", #selector(quit(_:)), "q"))
        statusItem?.menu = menu

        let appMenu = NSMenu()
        let appRoot = NSMenuItem()
        let commands = NSMenu()
        commands.addItem(menuItem("Pengaturan…", #selector(showSettings(_:)), ","))
        commands.addItem(menuItem("Buka island", #selector(openIsland(_:)), "i"))
        commands.addItem(menuItem("Keluar dari Tegak", #selector(quit(_:)), "q"))
        appRoot.submenu = commands
        appMenu.addItem(appRoot)
        let editRoot = NSMenuItem(title: "Edit", action: nil, keyEquivalent: "")
        let editMenu = NSMenu(title: "Edit")
        for (title, action, key) in [
            ("Potong", #selector(NSText.cut(_:)), "x"),
            ("Salin", #selector(NSText.copy(_:)), "c"),
            ("Tempel", #selector(NSText.paste(_:)), "v"),
            ("Pilih semua", #selector(NSText.selectAll(_:)), "a")
        ] {
            editMenu.addItem(NSMenuItem(title: title, action: action, keyEquivalent: key))
        }
        editRoot.submenu = editMenu
        appMenu.addItem(editRoot)
        NSApp.mainMenu = appMenu
    }

    private func menuItem(_ title: String, _ action: Selector, _ key: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        return item
    }

    func refresh() {
        countdownLabel.stringValue = engine.formattedRemaining
        let stateText: String
        switch engine.state {
        case .idle: stateText = "Belum dimulai. Mulai saat kamu siap."
        case .running: stateText = "Aktif · Setiap \(engine.intervalMinutes) menit"
        case .paused: stateText = "Dijeda · Lanjutkan saat kamu kembali"
        case .reminding: stateText = "Saatnya menyesuaikan posisi duduk"
        }
        stateLabel.stringValue = stateText
        countdownCaption.stringValue = engine.state == .reminding ? "Yuk, duduk lebih tegak." : "Pengingat berikutnya"
        startButton.title = toggleTitle
        startButton.needsDisplay = true
        menuToggle.title = toggleTitle
        menuStatus.title = engine.state == .running ? "Pengingat dalam \(engine.formattedRemaining)" : stateText
        statusItem?.button?.toolTip = "Tegak · \(stateText)"
        for button in presetButtons {
            let selected = button.tag == engine.intervalMinutes
            button.title = "\(selected ? "✓ " : "")\(button.tag) menit"
            button.style = selected ? .selected : .secondary
            button.setAccessibilityLabel("\(button.tag) menit\(selected ? ", dipilih" : "")")
        }
        if !customInputError && !isEditingInterval { intervalField.stringValue = "\(engine.intervalMinutes)" }
        updateIsland()
    }

    private var toggleTitle: String {
        switch engine.state {
        case .idle: return "Mulai pengingat"
        case .running: return "Jeda pengingat"
        case .paused: return "Lanjutkan pengingat"
        case .reminding: return "Sudah tegak, lanjutkan"
        }
    }

    private var targetScreen: NSScreen? {
        NSScreen.screens.first(where: { $0.safeAreaInsets.top > 0 }) ?? NSScreen.main ?? NSScreen.screens.first
    }

    private func updateIsland() {
        let screen = targetScreen
        guard screen != nil || isOffscreenTesting else { panel.orderOut(nil); return }
        let screenFrame = screen?.frame ?? NSRect(x: 0, y: 0, width: 1512, height: 982)
        topBand = max(34, screen?.safeAreaInsets.top ?? 0)
        let left = screen?.auxiliaryTopLeftArea ?? .zero
        let right = screen?.auxiliaryTopRightArea ?? .zero
        let notchWidth = left.isEmpty || right.isEmpty ? 180 : max(180, right.minX - left.maxX)
        compactWidth = min(screenFrame.width - 24, notchWidth + 156)
        expandedWidth = min(screenFrame.width - 24, max(480, compactWidth))
        let expanded = engine.isShowingReminder || userExpanded
        let width = expanded ? expandedWidth : compactWidth
        let height = expanded ? topBand + 144 : topBand + 4
        let frame = NSRect(x: screenFrame.midX - width / 2, y: screenFrame.maxY - height,
                           width: width, height: height)

        let shouldAnimate = lastExpanded != nil && lastExpanded != expanded && !isTesting
            && !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        if panel.frame != frame {
            if shouldAnimate {
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.22
                    panel.animator().setFrame(frame, display: true)
                }
            } else { panel.setFrame(frame, display: !isOffscreenTesting) }
        }
        lastExpanded = expanded
        islandSurface.frame.size = NSSize(width: width, height: height)
        islandSurface.needsDisplay = true
        islandLeft.frame = NSRect(x: 8, y: 2, width: 66, height: topBand - 2)
        islandRight.frame = NSRect(x: width - 76, y: 2, width: 68, height: topBand - 2)
        islandRight.title = engine.isShowingReminder ? "Postur"
            : engine.state == .running ? engine.formattedRemaining
            : engine.state == .idle ? "Siap" : "Dijeda"
        islandRight.needsDisplay = true
        islandHeading.frame = NSRect(x: 24, y: topBand + 10, width: width - 48, height: 30)
        islandSubtitle.frame = NSRect(x: 24, y: topBand + 45, width: width - 48, height: 24)
        islandPrimary.frame = NSRect(x: 24, y: topBand + 84, width: (width - 60) * 0.56, height: 36)
        islandSecondary.frame = NSRect(x: islandPrimary.frame.maxX + 12, y: topBand + 84,
                                       width: (width - 60) * 0.44, height: 36)
        for view in [islandHeading!, islandSubtitle!, islandPrimary!, islandSecondary!] { view.isHidden = !expanded }

        if engine.isShowingReminder {
            islandHeading.stringValue = "Yuk, duduk lebih tegak."
            islandSubtitle.stringValue = engine.isPreviewing && engine.state != .reminding
                ? "Ini preview. Jadwal pengingatmu tetap berjalan."
                : "Rilekskan bahu dan sesuaikan posisi dudukmu."
            islandPrimary.title = engine.state == .reminding ? "Sudah tegak" : "Tutup preview"
            islandSecondary.title = engine.state == .reminding ? "Tunda 5 menit" : "Pengaturan"
        } else {
            islandHeading.stringValue = engine.state == .running ? "Masih ada \(engine.formattedRemaining)." : "Ambil posisi nyaman."
            islandSubtitle.stringValue = engine.state == .running
                ? "Pengingat duduk setiap \(engine.intervalMinutes) menit."
                : "\(engine.state == .paused ? "Timer dijeda" : "Timer belum dimulai"). Lanjut saat kamu siap."
            islandPrimary.title = toggleTitle
            islandSecondary.title = "Pengaturan"
        }
        islandPrimary.needsDisplay = true
        islandSecondary.needsDisplay = true
        if !isOffscreenTesting { panel.orderFrontRegardless() }
    }

    @objc func toggleTimer(_ sender: Any?) {
        if !commitInterval() {
            showSettings(nil)
            settingsWindow.makeFirstResponder(intervalField)
            return
        }
        switch engine.state {
        case .idle, .paused: engine.start()
        case .running: engine.pause()
        case .reminding: engine.acknowledge()
        }
    }

    @objc func selectPreset(_ sender: ActionButton) {
        settingsWindow.makeFirstResponder(sender)
        customInputError = false
        isEditingInterval = false
        intervalField.stringValue = "\(sender.tag)"
        saveInterval(sender.tag)
    }

    @objc func applyCustomInterval(_ sender: Any?) { _ = commitInterval() }

    @discardableResult
    func commitInterval() -> Bool {
        guard let minutes = Int(intervalField.stringValue.trimmingCharacters(in: .whitespaces)),
              (1...180).contains(minutes) else {
            customInputError = true
            hintLabel.stringValue = "Isi angka bulat dari 1 sampai 180 menit."
            hintLabel.textColor = Palette.adaptive(0xA63E17, 0xF1A379)
            return false
        }
        customInputError = false
        if minutes != engine.intervalMinutes { saveInterval(minutes) }
        else { resetHint() }
        return true
    }

    private func saveInterval(_ minutes: Int) {
        preferences.set(minutes, forKey: "intervalMinutes")
        resetHint()
        engine.setInterval(minutes: minutes)
    }

    private func resetHint() {
        hintLabel.stringValue = "1–180 menit. Perubahan mengulang hitungan timer."
        hintLabel.textColor = Palette.secondary
    }

    func controlTextDidBeginEditing(_ obj: Notification) { isEditingInterval = true }
    func controlTextDidEndEditing(_ obj: Notification) {
        isEditingInterval = false
        _ = commitInterval()
    }

    @objc func toggleSound(_ sender: NSButton) {
        preferences.set(sender.state == .on, forKey: "soundEnabled")
    }

    @objc func preview(_ sender: Any?) { engine.preview() }

    @objc func toggleIsland(_ sender: Any?) {
        if engine.isShowingReminder { openIsland(sender); return }
        userExpanded.toggle()
        updateIsland()
        if userExpanded {
            if !isOffscreenTesting { panel.makeKey() }
            panel.makeFirstResponder(islandPrimary)
        }
    }

    @objc func openIsland(_ sender: Any?) {
        userExpanded = true
        updateIsland()
        if !isOffscreenTesting { panel.makeKeyAndOrderFront(nil) }
        panel.makeFirstResponder(islandPrimary)
    }

    func closeIsland() {
        userExpanded = false
        if engine.state == .reminding { engine.snooze() }
        else if engine.isPreviewing { engine.acknowledge() }
        else { updateIsland() }
        if panel.isKeyWindow { panel.resignKey() }
    }

    @objc func islandPrimaryAction(_ sender: Any?) {
        userExpanded = false
        if engine.isShowingReminder { engine.acknowledge() }
        else { toggleTimer(sender) }
    }

    @objc func islandSecondaryAction(_ sender: Any?) {
        if engine.state == .reminding {
            userExpanded = false
            engine.snooze()
        } else { showSettings(sender) }
    }

    @objc func showSettings(_ sender: Any?) {
        settingsPresentationRequested = true
        guard !isOffscreenTesting else { return }
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow.makeKeyAndOrderFront(nil)
    }

    private func hideSettings() {
        settingsPresentationRequested = false
        settingsWindow.orderOut(nil)
    }

    @objc private func didWake(_ notification: Notification) { engine.restartAfterWake() }
    @objc private func screenChanged(_ notification: Notification) { lastExpanded = nil; updateIsland() }
    @objc func quit(_ sender: Any?) { NSApp.terminate(nil) }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showSettings(nil)
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        timer?.invalidate()
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        NotificationCenter.default.removeObserver(self)
    }
}
