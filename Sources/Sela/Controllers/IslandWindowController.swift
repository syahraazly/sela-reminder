import AppKit
import SelaCore

@MainActor
final class IslandWindowController: NSObject {
    let panel: IslandPanel
    let contentView = IslandView()
    private let viewModel: ReminderViewModel
    private let isOffscreen: Bool
    private let animationsEnabled: Bool
    private var lastExpanded: Bool?

    init(viewModel: ReminderViewModel, isOffscreen: Bool, animationsEnabled: Bool) {
        self.viewModel = viewModel
        self.isOffscreen = isOffscreen
        self.animationsEnabled = animationsEnabled
        panel = IslandPanel(contentRect: NSRect(x: 0, y: 0, width: 480, height: 170),
            styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        super.init()
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = NSWindow.Level(rawValue: NSWindow.Level.statusBar.rawValue + 1)
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.isReleasedWhenClosed = false
        panel.contentView = contentView
        panel.onEscape = { [weak self] in self?.close() }
        for button in [contentView.leftButton, contentView.rightButton] {
            button.target = self
            button.action = #selector(toggle(_:))
        }
        contentView.primaryButton.target = self
        contentView.primaryButton.action = #selector(performPrimary(_:))
        contentView.secondaryButton.target = self
        contentView.secondaryButton.action = #selector(performSecondary(_:))
    }

    func render() {
        let screen = NSScreen.screens.first(where: { $0.safeAreaInsets.top > 0 })
            ?? NSScreen.main ?? NSScreen.screens.first
        guard screen != nil || isOffscreen else { panel.orderOut(nil); return }
        let screenFrame = screen?.frame ?? NSRect(x: 0, y: 0, width: 1512, height: 982)
        let topBand = max(34, screen?.safeAreaInsets.top ?? 0)
        let left = screen?.auxiliaryTopLeftArea ?? .zero
        let right = screen?.auxiliaryTopRightArea ?? .zero
        let notchWidth = left.isEmpty || right.isEmpty ? 180 : max(180, right.minX - left.maxX)
        let compactWidth = min(screenFrame.width - 24, notchWidth + 156)
        let expandedWidth = min(screenFrame.width - 24, max(480, compactWidth))
        let state = viewModel.island
        let size = NSSize(width: state.isExpanded ? expandedWidth : compactWidth,
                          height: state.isExpanded ? topBand + 144 : topBand + 4)
        let frame = NSRect(x: screenFrame.midX - size.width / 2,
                           y: screenFrame.maxY - size.height, width: size.width, height: size.height)
        let shouldAnimate = lastExpanded != nil && lastExpanded != state.isExpanded && animationsEnabled
            && !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        if panel.frame != frame {
            if shouldAnimate {
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.22
                    panel.animator().setFrame(frame, display: true)
                }
            } else { panel.setFrame(frame, display: !isOffscreen) }
        }
        lastExpanded = state.isExpanded
        contentView.render(state, size: size, topBand: topBand)
        if !isOffscreen { panel.orderFrontRegardless() }
    }

    func screenChanged() { lastExpanded = nil; render() }

    func open() {
        viewModel.openIsland()
        if !isOffscreen { panel.makeKeyAndOrderFront(nil) }
        panel.makeFirstResponder(contentView.primaryButton)
    }

    private func close() {
        viewModel.closeIsland()
        if panel.isKeyWindow { panel.resignKey() }
    }

    @objc private func toggle(_ sender: Any?) {
        viewModel.toggleIsland()
        if viewModel.island.isExpanded {
            if !isOffscreen { panel.makeKey() }
            panel.makeFirstResponder(contentView.primaryButton)
        }
    }

    @objc private func performPrimary(_ sender: Any?) { viewModel.performIslandPrimaryAction() }
    @objc private func performSecondary(_ sender: Any?) { viewModel.performIslandSecondaryAction() }
}
