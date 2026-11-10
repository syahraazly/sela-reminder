import Foundation
import Testing
@testable import TegakCore

@Suite @MainActor
struct ReminderEngineTests {
    @Test func reminderFiresOnceEvenAfterLongDelay() {
        var now = Date(timeIntervalSince1970: 1_000)
        let engine = ReminderEngine(intervalMinutes: 15, now: { now })
        var count = 0
        engine.onReminder = { count += 1 }
        engine.start()
        now = now.addingTimeInterval(3_600)
        engine.tick()
        engine.tick()
        #expect(engine.state == .reminding)
        #expect(count == 1)
        engine.acknowledge()
        #expect(engine.remaining == 900)
    }

    @Test func pauseResumesExactRemainingTime() {
        var now = Date(timeIntervalSince1970: 1_000)
        let engine = ReminderEngine(intervalMinutes: 30, now: { now })
        engine.start()
        now = now.addingTimeInterval(123)
        engine.pause()
        now = now.addingTimeInterval(5_000)
        #expect(engine.remaining == 1_677)
        engine.start()
        #expect(engine.remaining == 1_677)
    }

    @Test func previewDoesNotChangeCountdown() {
        var now = Date(timeIntervalSince1970: 1_000)
        let engine = ReminderEngine(now: { now })
        engine.start()
        let deadline = engine.deadline
        engine.preview()
        now = now.addingTimeInterval(5)
        engine.acknowledge()
        #expect(engine.deadline == deadline)
        #expect(engine.state == .running)
        #expect(!engine.isPreviewing)
    }

    @Test func snoozeIsFiveMinutesAndKeepsInterval() {
        var now = Date(timeIntervalSince1970: 1_000)
        let engine = ReminderEngine(intervalMinutes: 45, now: { now })
        engine.start()
        now = now.addingTimeInterval(2_700)
        engine.tick()
        engine.snooze()
        #expect(engine.remaining == 300)
        #expect(engine.intervalMinutes == 45)
        now = now.addingTimeInterval(300)
        engine.tick()
        #expect(engine.state == .reminding)
    }

    @Test func intervalValidationAndRescheduling() {
        let engine = ReminderEngine(intervalMinutes: -1)
        #expect(engine.intervalMinutes == 1)
        engine.setInterval(minutes: 999)
        #expect(engine.intervalMinutes == 180)
        engine.start()
        engine.setInterval(minutes: 15)
        #expect(engine.remaining > 899)
        #expect(engine.remaining <= 900)
        engine.pause()
        engine.setInterval(minutes: 60)
        #expect(engine.state == .paused)
        #expect(engine.remaining == 3_600)
    }

    @Test func wakeRestartsRunningTimerButPreservesPause() {
        var now = Date(timeIntervalSince1970: 1_000)
        let engine = ReminderEngine(now: { now })
        engine.start()
        now = now.addingTimeInterval(7_200)
        engine.restartAfterWake()
        #expect(engine.remaining == 1_800)
        engine.pause()
        now = now.addingTimeInterval(1_000)
        engine.restartAfterWake()
        #expect(engine.state == .paused)
        #expect(engine.remaining == 1_800)
    }

    @Test func deadlineDuringPreviewBecomesRealReminder() {
        var now = Date(timeIntervalSince1970: 1_000)
        let engine = ReminderEngine(intervalMinutes: 1, now: { now })
        engine.start()
        engine.preview()
        now = now.addingTimeInterval(60)
        engine.tick()
        #expect(engine.state == .reminding)
        #expect(!engine.isPreviewing)
        engine.acknowledge()
        #expect(engine.remaining == 60)
    }

    @Test func previewFromIdleDoesNotStartTimer() {
        let engine = ReminderEngine()
        engine.preview()
        #expect(engine.isShowingReminder)
        engine.acknowledge()
        #expect(engine.state == .idle)
        #expect(engine.deadline == nil)
    }
}
