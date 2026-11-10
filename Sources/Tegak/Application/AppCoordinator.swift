import AppKit
import TegakCore

@MainActor
final class AppCoordinator {
    let viewModel: ReminderViewModel
    let settingsController: SettingsWindowController
    let islandController: IslandWindowController
    let menuBarController: MenuBarController
    private let macOSService = MacOSReminderService()
    private let isTesting: Bool

    init(viewModel: ReminderViewModel, isOffscreen: Bool, isTesting: Bool) {
        self.viewModel = viewModel
        self.isTesting = isTesting
        settingsController = SettingsWindowController(viewModel: viewModel, isOffscreen: isOffscreen)
        islandController = IslandWindowController(viewModel: viewModel, isOffscreen: isOffscreen,
                                                  animationsEnabled: !isTesting)
        menuBarController = MenuBarController(viewModel: viewModel, isOffscreen: isOffscreen)
        bindViewModel()
        bindPlatformEvents()
    }

    func start() {
        render()
        if !isTesting {
            macOSService.start()
            settingsController.show()
        }
    }

    func stop() { macOSService.stop() }

    private func render() {
        settingsController.render()
        islandController.render()
        menuBarController.render()
    }

    private func bindViewModel() {
        viewModel.onChange = { [weak self] in self?.render() }
        viewModel.onRequestSettings = { [weak self] focusInterval in
            self?.settingsController.show(focusInterval: focusInterval)
        }
        if !isTesting {
            viewModel.onPlayReminderSound = { [weak self] in self?.macOSService.playReminderSound() }
        }
        menuBarController.onOpenSettings = { [weak self] in self?.settingsController.show() }
        menuBarController.onOpenIsland = { [weak self] in self?.islandController.open() }
    }

    private func bindPlatformEvents() {
        macOSService.onTick = { [weak self] in self?.viewModel.tick() }
        macOSService.onWake = { [weak self] in self?.viewModel.restartAfterWake() }
        macOSService.onScreenChange = { [weak self] in self?.islandController.screenChanged() }
    }
}
