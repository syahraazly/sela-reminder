import AppKit

@MainActor
enum Palette {
    static func color(_ hex: UInt32) -> NSColor {
        NSColor(srgbRed: CGFloat((hex >> 16) & 255) / 255,
                green: CGFloat((hex >> 8) & 255) / 255,
                blue: CGFloat(hex & 255) / 255, alpha: 1)
    }

    static func adaptive(_ light: UInt32, _ dark: UInt32) -> NSColor {
        NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            return NSColor(srgbRed: CGFloat(((isDark ? dark : light) >> 16) & 255) / 255,
                           green: CGFloat(((isDark ? dark : light) >> 8) & 255) / 255,
                           blue: CGFloat((isDark ? dark : light) & 255) / 255, alpha: 1)
        }
    }

    static let background = adaptive(0xF7F5F0, 0x20201E)
    static let surface = adaptive(0xEAE7E0, 0x2C2B28)
    static let text = adaptive(0x252421, 0xF7F5F0)
    static let secondary = adaptive(0x625E57, 0xBDB8AF)
    static let border = adaptive(0x878078, 0x88847C)
    static let accent = color(0xA63E17)
    static let islandAccent = color(0xF1A379)
    static let onBlackSecondary = color(0xBDB8AF)
}

@MainActor
final class SurfaceView: NSView {
    var fill: NSColor
    var radius: CGFloat
    override var isFlipped: Bool { true }

    init(fill: NSColor, radius: CGFloat = 0) {
        self.fill = fill
        self.radius = radius
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        fill.setFill()
        NSBezierPath(roundedRect: bounds, xRadius: radius, yRadius: radius).fill()
    }
}

@MainActor
final class ActionButton: NSButton {
    enum Style { case primary, secondary, selected, islandPrimary, islandSecondary, bare }
    var style: Style = .secondary { didSet { needsDisplay = true } }

    init(_ title: String, style: Style = .secondary, target: AnyObject?, action: Selector) {
        super.init(frame: .zero)
        self.title = title
        self.style = style
        self.target = target
        self.action = action
        isBordered = false
        setButtonType(.momentaryPushIn)
        font = .systemFont(ofSize: 13, weight: .semibold)
        focusRingType = .exterior
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }
    override var acceptsFirstResponder: Bool { true }
    override var canBecomeKeyView: Bool { isEnabled && !isHiddenOrHasHiddenAncestor }
    override var allowsVibrancy: Bool { false }
    override var focusRingMaskBounds: NSRect { bounds.insetBy(dx: -2, dy: -2) }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        needsDisplay = true
    }

    override func drawFocusRingMask() {
        NSBezierPath(roundedRect: focusRingMaskBounds, xRadius: 9, yRadius: 9).fill()
    }

    override func draw(_ dirtyRect: NSRect) {
        let background: NSColor
        let foreground: NSColor
        switch style {
        case .primary: background = Palette.accent; foreground = .white
        case .selected: background = Palette.text; foreground = Palette.background
        case .secondary: background = Palette.background; foreground = Palette.text
        case .islandPrimary: background = Palette.islandAccent; foreground = .black
        case .islandSecondary: background = Palette.color(0x202020); foreground = .white
        case .bare: background = .black; foreground = .white
        }
        let path = NSBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), xRadius: 8, yRadius: 8)
        (isHighlighted ? background.blended(withFraction: 0.15, of: foreground) ?? background : background).setFill()
        path.fill()
        if style == .secondary || style == .islandSecondary {
            Palette.border.setStroke()
            path.lineWidth = 1
            path.stroke()
        }
        let text = title as NSString
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font ?? NSFont.systemFont(ofSize: 13), .foregroundColor: foreground
        ]
        let size = text.size(withAttributes: attributes)
        text.draw(at: NSPoint(x: (bounds.width - size.width) / 2,
                             y: (bounds.height - size.height) / 2), withAttributes: attributes)
    }
}

@MainActor
final class KeyboardCheckbox: NSButton {
    override var acceptsFirstResponder: Bool { true }
    override var canBecomeKeyView: Bool { isEnabled && !isHiddenOrHasHiddenAncestor }
}

@MainActor
func label(_ text: String, size: CGFloat = 13, weight: NSFont.Weight = .regular,
           color: NSColor = Palette.text) -> NSTextField {
    let field = NSTextField(labelWithString: text)
    field.font = .systemFont(ofSize: size, weight: weight)
    field.textColor = color
    field.lineBreakMode = .byWordWrapping
    field.maximumNumberOfLines = 0
    return field
}

@MainActor
func place(_ child: NSView, in parent: NSView, _ x: CGFloat, _ y: CGFloat,
           _ width: CGFloat, _ height: CGFloat) {
    child.frame = NSRect(x: x, y: y, width: width, height: height)
    parent.addSubview(child)
}

@MainActor
final class SettingsWindow: NSWindow {
    var onEscape: (() -> Void)?
    override func cancelOperation(_ sender: Any?) { onEscape?() }
}

@MainActor
final class IslandPanel: NSPanel {
    var onEscape: (() -> Void)?
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
    override func cancelOperation(_ sender: Any?) { onEscape?() }
}

@MainActor
final class IslandSurface: NSView {
    override var isFlipped: Bool { true }
    override func draw(_ dirtyRect: NSRect) {
        let w = bounds.width
        let h = bounds.height
        let r: CGFloat = min(24, h / 2)
        let path = NSBezierPath()
        path.move(to: .zero)
        path.line(to: NSPoint(x: w, y: 0))
        path.line(to: NSPoint(x: w, y: h - r))
        path.curve(to: NSPoint(x: w - r, y: h),
                   controlPoint1: NSPoint(x: w, y: h - r * 0.45),
                   controlPoint2: NSPoint(x: w - r * 0.45, y: h))
        path.line(to: NSPoint(x: r, y: h))
        path.curve(to: NSPoint(x: 0, y: h - r),
                   controlPoint1: NSPoint(x: r * 0.45, y: h),
                   controlPoint2: NSPoint(x: 0, y: h - r * 0.45))
        path.close()
        NSColor.black.setFill()
        path.fill()
    }
}
