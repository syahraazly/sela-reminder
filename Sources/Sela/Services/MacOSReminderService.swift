import AppKit

@MainActor
final class MacOSReminderService: NSObject {
    var onTick: (() -> Void)?
    var onWake: (() -> Void)?
    var onScreenChange: (() -> Void)?
    private var timer: Timer?

    func start() {
        guard timer == nil else { return }
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.onTick?() }
        }
        timer.tolerance = 0.15
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(didWake),
            name: NSWorkspace.didWakeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(screenChanged),
            name: NSApplication.didChangeScreenParametersNotification, object: nil)
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        NotificationCenter.default.removeObserver(self)
    }

    func playReminderSound() { NSSound(named: "Pop")?.play() }
    @objc private func didWake(_ notification: Notification) { onWake?() }
    @objc private func screenChanged(_ notification: Notification) { onScreenChange?() }
}
