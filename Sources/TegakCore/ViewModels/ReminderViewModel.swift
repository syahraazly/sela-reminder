import Foundation

@MainActor
public final class ReminderViewModel {
    public var onChange: (() -> Void)?
    public var onRequestSettings: ((_ focusInterval: Bool) -> Void)?
    public var onPlayReminderSound: (() -> Void)?

    private let engine: ReminderEngine
    private let preferences: any ReminderPreferencesStore
    private var intervalInput: String
    private var isEditingInterval = false
    private var inputError: String?
    private var userExpandedIsland = false

    public init(preferences: any ReminderPreferencesStore, now: @escaping () -> Date = Date.init) {
        self.preferences = preferences
        let engine = ReminderEngine(intervalMinutes: preferences.intervalMinutes, now: now)
        self.engine = engine
        intervalInput = "\(engine.intervalMinutes)"
        engine.onChange = { [weak self] in self?.publishChanges() }
        engine.onReminder = { [weak self] in
            guard let self, self.preferences.soundEnabled else { return }
            self.onPlayReminderSound?()
        }
    }

    public var state: ReminderEngine.State { engine.state }
    public var intervalMinutes: Int { engine.intervalMinutes }
    public var remaining: TimeInterval { engine.remaining }
    public var nextReminderDate: Date? { engine.deadline }
    public var isPreviewing: Bool { engine.isPreviewing }
    public var soundEnabled: Bool { preferences.soundEnabled }
    public var reminderKind: ReminderKind { preferences.reminderKind }

    private var content: ReminderContent { ReminderContent(kind: reminderKind) }

    private var formattedRemaining: String {
        let seconds = Int(ceil(engine.remaining))
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    private var primaryTitle: String {
        switch engine.state {
        case .idle: return "Mulai pengingat"
        case .running: return "Jeda pengingat"
        case .paused: return "Lanjutkan pengingat"
        case .reminding: return "\(content.acknowledgement), lanjutkan"
        }
    }

    private var statusDescription: String {
        switch engine.state {
        case .idle: return "Belum dimulai. Mulai saat kamu siap."
        case .running: return "Aktif · \(content.name) · Setiap \(engine.intervalMinutes) menit"
        case .paused: return "Dijeda · Lanjutkan saat kamu kembali"
        case .reminding: return content.pendingDescription
        }
    }

    public var settings: SettingsViewState {
        SettingsViewState(
            countdown: formattedRemaining,
            caption: engine.state == .reminding ? content.heading : "Pengingat berikutnya",
            status: statusDescription,
            primaryTitle: primaryTitle,
            selectedInterval: engine.intervalMinutes,
            intervalInput: intervalInput,
            isEditingInterval: isEditingInterval,
            hint: inputError ?? "1–180 menit. Perubahan mengulang hitungan timer.",
            hasInputError: inputError != nil,
            soundEnabled: preferences.soundEnabled,
            selectedReminderKind: reminderKind
        )
    }

    public var island: IslandViewState {
        let compactTitle: String
        if engine.isShowingReminder { compactTitle = content.compactTitle }
        else {
            switch engine.state {
            case .running: compactTitle = formattedRemaining
            case .idle: compactTitle = "Siap"
            case .paused, .reminding: compactTitle = "Dijeda"
            }
        }
        if engine.isShowingReminder {
            return IslandViewState(
                isExpanded: true, compactTitle: compactTitle,
                heading: content.heading,
                subtitle: engine.isPreviewing && engine.state != .reminding
                    ? "Ini preview. Jadwal pengingatmu tetap berjalan."
                    : content.detail,
                primaryTitle: engine.state == .reminding ? content.acknowledgement : "Tutup preview",
                secondaryTitle: engine.state == .reminding ? "Tunda 5 menit" : "Pengaturan"
            )
        }
        return IslandViewState(
            isExpanded: userExpandedIsland, compactTitle: compactTitle,
            heading: engine.state == .running ? "Masih ada \(formattedRemaining)." : content.idleHeading,
            subtitle: engine.state == .running
                ? "Pengingat \(content.name.lowercased()) setiap \(engine.intervalMinutes) menit."
                : "\(engine.state == .paused ? "Timer dijeda" : "Timer belum dimulai"). Lanjut saat kamu siap.",
            primaryTitle: primaryTitle, secondaryTitle: "Pengaturan"
        )
    }

    public var menuBar: MenuBarViewState {
        MenuBarViewState(
            status: engine.state == .running ? "\(content.name) dalam \(formattedRemaining)" : statusDescription,
            primaryTitle: primaryTitle, toolTip: "Tegak · \(content.name) · \(statusDescription)",
            symbolName: content.menuSymbol, accessibilityLabel: "Tegak · Pengingat \(content.name.lowercased())"
        )
    }

    public func beginEditingInterval() { isEditingInterval = true }
    public func updateIntervalInput(_ text: String) { intervalInput = text }

    public func endEditingInterval(_ text: String) {
        isEditingInterval = false
        commitInterval(text)
    }

    @discardableResult
    public func commitInterval(_ text: String? = nil) -> Bool {
        if let text { intervalInput = text }
        guard let minutes = Int(intervalInput.trimmingCharacters(in: .whitespaces)),
              (1...180).contains(minutes) else {
            inputError = "Isi angka bulat dari 1 sampai 180 menit."
            publishChanges()
            return false
        }
        inputError = nil
        if minutes != engine.intervalMinutes { saveInterval(minutes) }
        else { publishChanges() }
        return true
    }

    public func selectPreset(_ minutes: Int) {
        guard (1...180).contains(minutes) else { return }
        isEditingInterval = false
        inputError = nil
        intervalInput = "\(minutes)"
        saveInterval(minutes)
    }

    public func toggleTimer() {
        guard commitInterval() else { onRequestSettings?(true); return }
        switch engine.state {
        case .idle, .paused: engine.start()
        case .running: engine.pause()
        case .reminding: engine.acknowledge()
        }
    }

    public func setSoundEnabled(_ enabled: Bool) {
        preferences.soundEnabled = enabled
        publishChanges()
    }

    public func selectReminderKind(_ kind: ReminderKind) {
        preferences.reminderKind = kind
        publishChanges()
    }

    public func tick() { engine.tick() }
    public func restartAfterWake() { engine.restartAfterWake() }
    public func preview() { engine.preview() }

    public func toggleIsland() {
        userExpandedIsland = engine.isShowingReminder || !userExpandedIsland
        publishChanges()
    }

    public func openIsland() {
        userExpandedIsland = true
        publishChanges()
    }

    public func closeIsland() {
        userExpandedIsland = false
        if engine.state == .reminding { engine.snooze() }
        else if engine.isPreviewing { engine.acknowledge() }
        else { publishChanges() }
    }

    public func performIslandPrimaryAction() {
        userExpandedIsland = false
        if engine.isShowingReminder { engine.acknowledge() }
        else { toggleTimer() }
    }

    public func performIslandSecondaryAction() {
        if engine.state == .reminding {
            userExpandedIsland = false
            engine.snooze()
        } else { onRequestSettings?(false) }
    }

    private func saveInterval(_ minutes: Int) {
        preferences.intervalMinutes = minutes
        engine.setInterval(minutes: minutes)
    }

    private func publishChanges() {
        if !isEditingInterval && inputError == nil { intervalInput = "\(engine.intervalMinutes)" }
        onChange?()
    }
}
