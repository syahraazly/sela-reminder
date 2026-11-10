import Foundation

@MainActor
public final class ReminderEngine {
    public enum State: Equatable { case idle, running, paused, reminding }

    public private(set) var state: State = .idle
    public private(set) var intervalMinutes: Int
    public private(set) var isPreviewing = false
    public private(set) var deadline: Date?
    public var onChange: (() -> Void)?
    public var onReminder: (() -> Void)?

    private var pausedSeconds: TimeInterval = 0
    private let now: () -> Date

    public init(intervalMinutes: Int = 30, now: @escaping () -> Date = Date.init) {
        self.intervalMinutes = min(180, max(1, intervalMinutes))
        self.now = now
    }

    public var remaining: TimeInterval {
        switch state {
        case .running: return max(0, (deadline ?? now()).timeIntervalSince(now()))
        case .paused: return pausedSeconds
        case .idle: return TimeInterval(intervalMinutes * 60)
        case .reminding: return 0
        }
    }

    public var isShowingReminder: Bool { state == .reminding || isPreviewing }

    public func start() {
        let duration = state == .paused ? pausedSeconds : TimeInterval(intervalMinutes * 60)
        deadline = now().addingTimeInterval(duration)
        state = .running
        isPreviewing = false
        onChange?()
    }

    public func pause() {
        guard state == .running || state == .reminding else { return }
        pausedSeconds = state == .running ? remaining : TimeInterval(intervalMinutes * 60)
        state = .paused
        deadline = nil
        isPreviewing = false
        onChange?()
    }

    public func setInterval(minutes: Int) {
        intervalMinutes = min(180, max(1, minutes))
        if state == .running { deadline = now().addingTimeInterval(TimeInterval(intervalMinutes * 60)) }
        if state == .paused { pausedSeconds = TimeInterval(intervalMinutes * 60) }
        onChange?()
    }

    public func tick() {
        if state == .running, let deadline, now() >= deadline {
            state = .reminding
            self.deadline = nil
            isPreviewing = false
            onReminder?()
        }
        onChange?()
    }

    public func preview() {
        isPreviewing = true
        onChange?()
    }

    public func acknowledge() {
        if state == .reminding {
            start()
        } else {
            isPreviewing = false
            onChange?()
        }
    }

    public func snooze() {
        guard state == .reminding else { return }
        isPreviewing = false
        deadline = now().addingTimeInterval(5 * 60)
        state = .running
        onChange?()
    }

    public func restartAfterWake() {
        guard state == .running else { return }
        deadline = now().addingTimeInterval(TimeInterval(intervalMinutes * 60))
        onChange?()
    }

    public var formattedRemaining: String {
        let seconds = Int(ceil(remaining))
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}
