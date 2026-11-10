import AppKit
import TegakCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let isTesting = CommandLine.arguments.contains("--smoke-test")
    var isOffscreenTesting: Bool { isTesting && NSScreen.screens.isEmpty }
    private var coordinator: AppCoordinator?

    func applicationDidFinishLaunching(_ notification: Notification) {
        if isTesting {
            let runner = SmokeTestRunner(isOffscreen: isOffscreenTesting)
            coordinator = runner.coordinator
            runner.coordinator.start()
            if isOffscreenTesting { runner.run() }
            else { DispatchQueue.main.async { runner.run() } }
        } else {
            let preferences = UserDefaultsReminderPreferences()
            let coordinator = AppCoordinator(viewModel: ReminderViewModel(preferences: preferences),
                                             isOffscreen: false, isTesting: false)
            self.coordinator = coordinator
            coordinator.start()
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        coordinator?.settingsController.show()
        return true
    }

    func applicationWillTerminate(_ notification: Notification) { coordinator?.stop() }
}
