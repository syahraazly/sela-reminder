import AppKit
import SelaCore

@MainActor
final class SettingsWindowController: NSObject, NSTextFieldDelegate {
    let window: SettingsWindow
    let contentView = SettingsView()
    private(set) var presentationRequested = false
    private let viewModel: ReminderViewModel
    private let isOffscreen: Bool

    init(viewModel: ReminderViewModel, isOffscreen: Bool) {
        self.viewModel = viewModel
        self.isOffscreen = isOffscreen
        window = SettingsWindow(contentRect: NSRect(x: 0, y: 0, width: 520, height: 650),
            styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
        super.init()
        window.title = AppIdentity.name
        window.titlebarAppearsTransparent = true
        window.backgroundColor = Palette.background
        window.isReleasedWhenClosed = false
        window.center()
        window.contentView = contentView
        window.initialFirstResponder = contentView.startButton
        window.onEscape = { [weak self] in self?.hide() }
        bindActions()
        render()
    }

    func render() { contentView.render(viewModel.settings) }

    func show(focusInterval: Bool = false) {
        presentationRequested = true
        if !isOffscreen {
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
        }
        if focusInterval { window.makeFirstResponder(contentView.intervalField) }
    }

    private func hide() {
        presentationRequested = false
        window.orderOut(nil)
    }

    private func bindActions() {
        for button in contentView.reminderKindButtons {
            button.target = self
            button.action = #selector(selectReminderKind(_:))
        }
        for button in contentView.presetButtons {
            button.target = self
            button.action = #selector(selectPreset(_:))
        }
        let actions: [(NSControl, Selector)] = [
            (contentView.intervalField, #selector(applyCustomInterval(_:))),
            (contentView.soundButton, #selector(toggleSound(_:))),
            (contentView.startButton, #selector(toggleTimer(_:))),
            (contentView.previewButton, #selector(preview(_:)))
        ]
        for (control, action) in actions { control.target = self; control.action = action }
        contentView.intervalField.delegate = self
    }

    @objc private func selectPreset(_ sender: ActionButton) {
        window.makeFirstResponder(sender)
        viewModel.selectPreset(sender.tag)
    }

    @objc private func selectReminderKind(_ sender: ActionButton) {
        guard let identifier = sender.identifier?.rawValue, let kind = ReminderKind(rawValue: identifier) else { return }
        window.makeFirstResponder(sender)
        viewModel.selectReminderKind(kind)
    }

    @objc private func applyCustomInterval(_ sender: NSTextField) { viewModel.commitInterval(sender.stringValue) }
    @objc private func toggleSound(_ sender: NSButton) { viewModel.setSoundEnabled(sender.state == .on) }
    @objc private func preview(_ sender: Any?) { viewModel.preview() }
    @objc private func toggleTimer(_ sender: Any?) {
        viewModel.updateIntervalInput(contentView.intervalField.stringValue)
        viewModel.toggleTimer()
    }

    func controlTextDidBeginEditing(_ obj: Notification) { viewModel.beginEditingInterval() }
    func controlTextDidChange(_ obj: Notification) {
        viewModel.updateIntervalInput(contentView.intervalField.stringValue)
    }
    func controlTextDidEndEditing(_ obj: Notification) {
        viewModel.endEditingInterval(contentView.intervalField.stringValue)
    }
}
