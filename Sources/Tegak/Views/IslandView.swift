import AppKit
import TegakCore

@MainActor
final class IslandView: IslandSurface {
    let leftButton = ActionButton("Tegak", style: .bare)
    let rightButton = ActionButton("30:00", style: .bare)
    let primaryButton = ActionButton("Sudah tegak", style: .islandPrimary)
    let secondaryButton = ActionButton("Tunda 5 menit", style: .islandSecondary)
    private let headingLabel = label("Yuk, duduk lebih tegak.", size: 21, weight: .semibold, color: .white)
    private let subtitleLabel = label("Rilekskan bahu dan sesuaikan posisi dudukmu.", size: 12, color: Palette.onBlackSecondary)

    init() {
        super.init(frame: .zero)
        leftButton.font = .systemFont(ofSize: 11, weight: .semibold)
        leftButton.setAccessibilityLabel("Buka atau tutup island Tegak")
        rightButton.font = .monospacedDigitSystemFont(ofSize: 11, weight: .medium)
        rightButton.setAccessibilityLabel("Buka status pengingat")
        for child in [leftButton, rightButton, headingLabel, subtitleLabel, primaryButton, secondaryButton] {
            addSubview(child)
        }
        leftButton.nextKeyView = rightButton
        rightButton.nextKeyView = primaryButton
        primaryButton.nextKeyView = secondaryButton
        secondaryButton.nextKeyView = leftButton
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }

    func render(_ state: IslandViewState, size: NSSize, topBand: CGFloat) {
        frame.size = size
        needsDisplay = true
        let width = size.width
        leftButton.frame = NSRect(x: 8, y: 2, width: 66, height: topBand - 2)
        rightButton.frame = NSRect(x: width - 76, y: 2, width: 68, height: topBand - 2)
        headingLabel.frame = NSRect(x: 24, y: topBand + 10, width: width - 48, height: 30)
        subtitleLabel.frame = NSRect(x: 24, y: topBand + 45, width: width - 48, height: 24)
        primaryButton.frame = NSRect(x: 24, y: topBand + 84, width: (width - 60) * 0.56, height: 36)
        secondaryButton.frame = NSRect(x: primaryButton.frame.maxX + 12, y: topBand + 84,
                                       width: (width - 60) * 0.44, height: 36)
        for child in [headingLabel, subtitleLabel, primaryButton, secondaryButton] {
            child.isHidden = !state.isExpanded
        }
        rightButton.title = state.compactTitle
        headingLabel.stringValue = state.heading
        subtitleLabel.stringValue = state.subtitle
        primaryButton.title = state.primaryTitle
        secondaryButton.title = state.secondaryTitle
        for button in [rightButton, primaryButton, secondaryButton] { button.needsDisplay = true }
    }
}
