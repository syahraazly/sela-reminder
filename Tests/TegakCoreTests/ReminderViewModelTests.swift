import Foundation
import Testing
@testable import TegakCore

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
        #expect(viewModel.island.primaryTitle == "Tutup preview")
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
}

@MainActor
private final class MemoryReminderPreferences: ReminderPreferencesStore {
    var intervalMinutes: Int
    var soundEnabled: Bool

    init(intervalMinutes: Int = 30, soundEnabled: Bool = false) {
        self.intervalMinutes = intervalMinutes
        self.soundEnabled = soundEnabled
    }
}
