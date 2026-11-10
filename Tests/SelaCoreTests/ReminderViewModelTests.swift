import Foundation
import Testing
@testable import SelaCore

@Suite @MainActor
struct ReminderViewModelTests {
    @Test func restoresPreferencesWithoutStartingTimer() {
        let preferences = MemoryReminderPreferences(intervalMinutes: 45, soundEnabled: true)
        let viewModel = ReminderViewModel(preferences: preferences)
        #expect(viewModel.state == .idle)
        #expect(viewModel.settings.countdown == "45:00")
        #expect(viewModel.settings.intervalInput == "45")
        #expect(viewModel.settings.soundEnabled)
        #expect(viewModel.settings.primaryTitle == "Mulai pengingat")
        #expect(viewModel.island.compactTitle == "Siap")
        #expect(!viewModel.island.isExpanded)
    }

    @Test func invalidInputSurvivesTimerUpdatesWithoutChangingPreferences() {
        let preferences = MemoryReminderPreferences()
        let viewModel = ReminderViewModel(preferences: preferences)
        viewModel.toggleTimer()
        let deadline = viewModel.nextReminderDate
        #expect(!viewModel.commitInterval("181"))
        viewModel.tick()
        #expect(viewModel.settings.hasInputError)
        #expect(viewModel.settings.intervalInput == "181")
        #expect(preferences.intervalMinutes == 30)
        #expect(viewModel.nextReminderDate == deadline)
        #expect(viewModel.commitInterval("22"))
        #expect(!viewModel.settings.hasInputError)
        #expect(preferences.intervalMinutes == 22)
    }

    @Test func tickingDoesNotOverwriteAnUnfinishedEdit() {
        let viewModel = ReminderViewModel(preferences: MemoryReminderPreferences())
        viewModel.toggleTimer()
        viewModel.beginEditingInterval()
        viewModel.updateIntervalInput("4")
        viewModel.tick()
        #expect(viewModel.settings.intervalInput == "4")
        #expect(viewModel.settings.selectedInterval == 30)
        #expect(viewModel.settings.isEditingInterval)
        viewModel.endEditingInterval("45")
        #expect(viewModel.intervalMinutes == 45)
        #expect(!viewModel.settings.isEditingInterval)
    }

    @Test func committingUnchangedInputPreservesDeadlineWhilePresetRestartsIt() {
        var now = Date(timeIntervalSince1970: 1_000)
        let preferences = MemoryReminderPreferences()
        let viewModel = ReminderViewModel(preferences: preferences, now: { now })
        #expect(viewModel.commitInterval(" 22 "))
        #expect(viewModel.settings.intervalInput == "22")
        viewModel.toggleTimer()
        let deadline = viewModel.nextReminderDate
        now = now.addingTimeInterval(30)
        viewModel.commitInterval("22")
        #expect(viewModel.nextReminderDate == deadline)
        viewModel.selectPreset(22)
        #expect(viewModel.remaining == 1_320)
        #expect(viewModel.nextReminderDate != deadline)
    }

    @Test func invalidInputRequestsSettingsAndPreventsTimerAction() {
        let viewModel = ReminderViewModel(preferences: MemoryReminderPreferences())
        var focusRequests: [Bool] = []
        viewModel.onRequestSettings = { focusRequests.append($0) }
        viewModel.updateIntervalInput("abc")
        viewModel.toggleTimer()
        #expect(viewModel.state == .idle)
        #expect(focusRequests == [true])
        viewModel.selectPreset(15)
        viewModel.toggleTimer()
        #expect(viewModel.state == .running)
        #expect(!viewModel.settings.hasInputError)
    }

    @Test func previewAndIslandExpansionPreserveTheRunningDeadline() {
        let viewModel = ReminderViewModel(preferences: MemoryReminderPreferences())
        viewModel.toggleTimer()
        let deadline = viewModel.nextReminderDate
        viewModel.openIsland()
        #expect(viewModel.island.isExpanded)
        viewModel.closeIsland()
        #expect(!viewModel.island.isExpanded)
        viewModel.preview()
        #expect(viewModel.island.primaryTitle == "Tutup contoh")
        viewModel.performIslandPrimaryAction()
        #expect(!viewModel.isPreviewing)
        #expect(viewModel.state == .running)
        #expect(viewModel.nextReminderDate == deadline)
    }

    @Test func realReminderPresentationAndSnoozeStayInSyncAcrossViews() {
        var now = Date(timeIntervalSince1970: 1_000)
        let preferences = MemoryReminderPreferences(intervalMinutes: 1)
        let viewModel = ReminderViewModel(preferences: preferences, now: { now })
        viewModel.toggleTimer()
        now = now.addingTimeInterval(60)
        viewModel.tick()
        #expect(viewModel.state == .reminding)
        #expect(viewModel.settings.countdown == "00:00")
        #expect(viewModel.settings.primaryTitle == "Sudah tegak, lanjutkan")
        #expect(viewModel.island.primaryTitle == "Sudah tegak")
        #expect(viewModel.island.secondaryTitle == "Tunda 5 menit")
        #expect(viewModel.menuBar.primaryTitle == viewModel.settings.primaryTitle)
        viewModel.performIslandSecondaryAction()
        #expect(viewModel.remaining == 300)
        #expect(!viewModel.island.isExpanded)
        #expect(viewModel.settings.countdown == "05:00")
        #expect(preferences.intervalMinutes == 1)
    }

    @Test func soundIsOnlyRequestedForEnabledRealReminders() {
        var now = Date(timeIntervalSince1970: 1_000)
        let preferences = MemoryReminderPreferences(intervalMinutes: 1)
        let viewModel = ReminderViewModel(preferences: preferences, now: { now })
        var sounds = 0
        viewModel.onPlayReminderSound = { sounds += 1 }
        viewModel.preview()
        #expect(sounds == 0)
        viewModel.closeIsland()
        viewModel.toggleTimer()
        now = now.addingTimeInterval(60)
        viewModel.tick()
        #expect(sounds == 0)
        viewModel.performIslandPrimaryAction()
        viewModel.setSoundEnabled(true)
        #expect(preferences.soundEnabled)
        now = now.addingTimeInterval(60)
        viewModel.tick()
        viewModel.tick()
        #expect(sounds == 1)
    }

    @Test func settingsRoutingDoesNotDismissPreviewOrResetTimer() {
        let viewModel = ReminderViewModel(preferences: MemoryReminderPreferences())
        var requests: [Bool] = []
        viewModel.onRequestSettings = { requests.append($0) }
        viewModel.toggleTimer()
        let deadline = viewModel.nextReminderDate
        viewModel.preview()
        viewModel.performIslandSecondaryAction()
        #expect(requests == [false])
        #expect(viewModel.isPreviewing)
        #expect(viewModel.nextReminderDate == deadline)
    }

    @Test func publishesUpdatedPresentationAfterModelAndPreferenceChanges() {
        var now = Date(timeIntervalSince1970: 1_000)
        let viewModel = ReminderViewModel(preferences: MemoryReminderPreferences(), now: { now })
        var snapshots: [SettingsViewState] = []
        viewModel.onChange = { snapshots.append(viewModel.settings) }
        viewModel.toggleTimer()
        now = now.addingTimeInterval(1)
        viewModel.tick()
        #expect(snapshots.last?.countdown == "29:59")
        viewModel.setSoundEnabled(true)
        #expect(snapshots.last?.soundEnabled == true)
        viewModel.commitInterval("invalid")
        #expect(snapshots.last?.hasInputError == true)
    }

    @Test func restoresWaterChoiceWithoutStartingTimer() {
        let preferences = MemoryReminderPreferences(intervalMinutes: 45, reminderKind: .water)
        let viewModel = ReminderViewModel(preferences: preferences)
        #expect(viewModel.reminderKind == .water)
        #expect(viewModel.settings.selectedReminderKind == .water)
        #expect(viewModel.settings.countdown == "45:00")
        #expect(viewModel.island.heading == "Siapkan air minummu.")
        #expect(viewModel.menuBar.symbolName == "drop")
        #expect(viewModel.state == .idle)
    }

    @Test func switchingKindPreservesRunningAndPausedTimers() {
        var now = Date(timeIntervalSince1970: 1_000)
        let preferences = MemoryReminderPreferences()
        let viewModel = ReminderViewModel(preferences: preferences, now: { now })
        viewModel.toggleTimer()
        now = now.addingTimeInterval(43)
        let deadline = viewModel.nextReminderDate
        viewModel.selectReminderKind(.water)
        #expect(preferences.reminderKind == .water)
        #expect(viewModel.nextReminderDate == deadline)
        #expect(viewModel.remaining == 1_757)
        #expect(viewModel.settings.status.contains("Minum air putih"))
        #expect(viewModel.menuBar.status.contains("Minum air putih"))
        viewModel.toggleTimer()
        viewModel.selectReminderKind(.posture)
        #expect(viewModel.state == .paused)
        #expect(viewModel.remaining == 1_757)
        #expect(viewModel.intervalMinutes == 30)
    }

    @Test func waterPreviewUsesSelectedContentWithoutChangingDeadline() {
        let viewModel = ReminderViewModel(preferences: MemoryReminderPreferences(reminderKind: .water))
        viewModel.toggleTimer()
        let deadline = viewModel.nextReminderDate
        viewModel.preview()
        #expect(viewModel.island.heading == "Yuk, minum air putih.")
        #expect(viewModel.island.compactTitle == "Minum")
        #expect(viewModel.island.primaryTitle == "Tutup contoh")
        viewModel.performIslandPrimaryAction()
        #expect(viewModel.nextReminderDate == deadline)
        #expect(viewModel.state == .running)
        #expect(!viewModel.isPreviewing)
    }

    @Test func waterReminderAcknowledgementStartsNextInterval() {
        var now = Date(timeIntervalSince1970: 1_000)
        let preferences = MemoryReminderPreferences(intervalMinutes: 1, reminderKind: .water)
        let viewModel = ReminderViewModel(preferences: preferences, now: { now })
        viewModel.toggleTimer()
        now = now.addingTimeInterval(60)
        viewModel.tick()
        #expect(viewModel.settings.caption == "Yuk, minum air putih.")
        #expect(viewModel.settings.primaryTitle == "Sudah minum, lanjutkan")
        #expect(viewModel.island.primaryTitle == "Sudah minum")
        #expect(viewModel.island.subtitle == "Ambil jeda sebentar untuk minum air putih.")
        viewModel.performIslandPrimaryAction()
        #expect(viewModel.state == .running)
        #expect(viewModel.remaining == 60)
        #expect(viewModel.reminderKind == .water)
    }

    @Test func changingKindDuringReminderDoesNotReplaySound() {
        var now = Date(timeIntervalSince1970: 1_000)
        let preferences = MemoryReminderPreferences(intervalMinutes: 1, soundEnabled: true)
        let viewModel = ReminderViewModel(preferences: preferences, now: { now })
        var sounds = 0
        viewModel.onPlayReminderSound = { sounds += 1 }
        viewModel.toggleTimer()
        now = now.addingTimeInterval(60)
        viewModel.tick()
        viewModel.selectReminderKind(.water)
        #expect(viewModel.state == .reminding)
        #expect(viewModel.island.primaryTitle == "Sudah minum")
        #expect(sounds == 1)
        viewModel.closeIsland()
        #expect(viewModel.remaining == 300)
    }

    @Test func userDefaultsRestoresKindAndHandlesLegacyOrUnknownValues() throws {
        let suite = "local.dummy.sela.preferences-test.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(45, forKey: "intervalMinutes")
        defaults.set(true, forKey: "soundEnabled")
        let preferences = UserDefaultsReminderPreferences(defaults: defaults)
        #expect(preferences.reminderKind == .posture)
        preferences.reminderKind = .water
        let restored = UserDefaultsReminderPreferences(defaults: defaults)
        #expect(restored.reminderKind == .water)
        #expect(restored.intervalMinutes == 45)
        #expect(restored.soundEnabled)
        defaults.set("unknown-kind", forKey: "reminderKind")
        #expect(restored.reminderKind == .posture)
    }

    @Test func previewUsesReminderContentWhenTimerIsIdleOrPaused() {
        for kind in ReminderKind.allCases {
            let viewModel = ReminderViewModel(preferences: MemoryReminderPreferences(reminderKind: kind))
            let detail = kind == .posture
                ? "Rilekskan bahu dan sesuaikan posisi dudukmu."
                : "Ambil jeda sebentar untuk minum air putih."
            viewModel.preview()
            #expect(viewModel.state == .idle)
            #expect(viewModel.island.subtitle == detail)
            #expect(viewModel.island.primaryTitle == "Tutup contoh")
            viewModel.closeIsland()
            viewModel.toggleTimer()
            viewModel.toggleTimer()
            let remaining = viewModel.remaining
            viewModel.preview()
            #expect(viewModel.state == .paused)
            #expect(viewModel.island.subtitle == detail)
            viewModel.closeIsland()
            #expect(viewModel.remaining == remaining)
        }
    }
}

@MainActor
private final class MemoryReminderPreferences: ReminderPreferencesStore {
    var intervalMinutes: Int
    var soundEnabled: Bool
    var reminderKind: ReminderKind

    init(intervalMinutes: Int = 30, soundEnabled: Bool = false, reminderKind: ReminderKind = .posture) {
        self.intervalMinutes = intervalMinutes
        self.soundEnabled = soundEnabled
        self.reminderKind = reminderKind
    }
}
