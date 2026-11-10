import AppKit
import TegakCore

@MainActor
final class MenuBarController: NSObject {
    var onOpenSettings: (() -> Void)?
    var onOpenIsland: (() -> Void)?

    private let viewModel: ReminderViewModel
    private let statusLabel = NSMenuItem(title: "Tegak · Belum dimulai", action: nil, keyEquivalent: "")
    private var toggleItem: NSMenuItem!
    private var statusItem: NSStatusItem?

    init(viewModel: ReminderViewModel, isOffscreen: Bool) {
        self.viewModel = viewModel
        super.init()
        if !isOffscreen { createStatusItem() }
        let menu = NSMenu()
        menu.addItem(statusLabel)
        menu.addItem(.separator())
        toggleItem = item("Mulai pengingat", #selector(toggleTimer(_:)), "s")
        menu.addItem(toggleItem)
        menu.addItem(item("Coba pengingat", #selector(preview(_:)), "p"))
        menu.addItem(item("Buka island", #selector(openIsland(_:)), "i"))
        menu.addItem(.separator())
        menu.addItem(item("Pengaturan…", #selector(openSettings(_:)), ","))
        menu.addItem(item("Keluar dari Tegak", #selector(quit(_:)), "q"))
        statusItem?.menu = menu
        createMainMenu()
    }

    func render() {
        let state = viewModel.menuBar
        statusLabel.title = state.status
        toggleItem.title = state.primaryTitle
        statusItem?.button?.toolTip = state.toolTip
    }

    private func createStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let image = NSImage(systemSymbolName: "figure.seated.side", accessibilityDescription: "Tegak, pengingat duduk") {
            image.isTemplate = true
            item.button?.image = image
        } else { item.button?.title = "T" }
        statusItem = item
    }

    private func createMainMenu() {
        let mainMenu = NSMenu()
        let appRoot = NSMenuItem()
        let commands = NSMenu()
        commands.addItem(item("Pengaturan…", #selector(openSettings(_:)), ","))
        commands.addItem(item("Buka island", #selector(openIsland(_:)), "i"))
        commands.addItem(item("Keluar dari Tegak", #selector(quit(_:)), "q"))
        appRoot.submenu = commands
        mainMenu.addItem(appRoot)
        let editRoot = NSMenuItem(title: "Edit", action: nil, keyEquivalent: "")
        let editMenu = NSMenu(title: "Edit")
        for (title, action, key) in [
            ("Potong", #selector(NSText.cut(_:)), "x"),
            ("Salin", #selector(NSText.copy(_:)), "c"),
            ("Tempel", #selector(NSText.paste(_:)), "v"),
            ("Pilih semua", #selector(NSText.selectAll(_:)), "a")
        ] { editMenu.addItem(NSMenuItem(title: title, action: action, keyEquivalent: key)) }
        editRoot.submenu = editMenu
        mainMenu.addItem(editRoot)
        NSApp.mainMenu = mainMenu
    }

    private func item(_ title: String, _ action: Selector, _ key: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        return item
    }

    @objc private func toggleTimer(_ sender: Any?) { viewModel.toggleTimer() }
    @objc private func preview(_ sender: Any?) { viewModel.preview() }
    @objc private func openSettings(_ sender: Any?) { onOpenSettings?() }
    @objc private func openIsland(_ sender: Any?) { onOpenIsland?() }
    @objc private func quit(_ sender: Any?) { NSApp.terminate(nil) }
}
