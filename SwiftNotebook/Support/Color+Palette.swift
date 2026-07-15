import SwiftUI
import AppKit

extension NSColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(
            srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }

    /// A true dynamic color that re-resolves on every appearance change — including for views
    /// (like `NSTextView`) that only read `.textColor`/attribute colors at draw time rather than
    /// being re-configured by SwiftUI when the system appearance switches.
    convenience init(light: NSColor, dark: NSColor) {
        self.init(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? dark : light
        }
    }
}

extension Color {
    /// Wraps a dynamic `NSColor` so SwiftUI views adapt automatically with the system appearance.
    init(light: NSColor, dark: NSColor) {
        self.init(nsColor: NSColor(light: light, dark: dark))
    }

    /// A plain, non-adaptive color from a hex string like `"B23A2E"` — used for user-chosen
    /// category colors, which (like a user's own color picks in any app) are a fixed color rather
    /// than a light/dark pair.
    init(hex: String) {
        let value = UInt32(hex, radix: 16) ?? 0x8A857C
        self.init(
            .sRGB,
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255,
            opacity: 1
        )
    }

    /// Inverse of `init(hex:)`, used to store a `ColorPicker`-selected color back as a hex string.
    var hexString: String {
        guard let components = NSColor(self).usingColorSpace(.sRGB) else { return "8A857C" }
        let r = Int((components.redComponent * 255).rounded())
        let g = Int((components.greenComponent * 255).rounded())
        let b = Int((components.blueComponent * 255).rounded())
        return String(format: "%02X%02X%02X", r, g, b)
    }
}

/// Warm palette from the design handoff, with a parallel dark variant for each token — the
/// handoff only specified light-mode values, so dark equivalents are our own judgment call,
/// keeping the same warm (not neutral-grey) character and the same accent hue.
enum Palette {
    static let accent = Color(light: NSColor(hex: 0xB23A2E), dark: NSColor(hex: 0xE0584A))
    static let inkPrimary = Color(light: NSColor(hex: 0x1C1B19), dark: NSColor(hex: 0xF3F0EA))
    static let inkBodyPreview = Color(light: NSColor(hex: 0x26231E), dark: NSColor(hex: 0xEDE9E1))
    static let inkBodyWrite = Color(light: NSColor(hex: 0x33302A), dark: NSColor(hex: 0xE4E0D8))
    static let ink2621 = Color(light: NSColor(hex: 0x2A2621), dark: NSColor(hex: 0xEAE6DE))
    static let inkSecondary = Color(light: NSColor(hex: 0x8A857C), dark: NSColor(hex: 0xACA594))
    static let inkTertiary = Color(light: NSColor(hex: 0xA8A294), dark: NSColor(hex: 0x8B8474))
    static let inkQuaternary = Color(light: NSColor(hex: 0xC1B9AB), dark: NSColor(hex: 0x6B6558))
    static let weekdayLetter = Color(light: NSColor(hex: 0xBCB4A6), dark: NSColor(hex: 0x6B6558))
    static let iconDefault = Color(light: NSColor(hex: 0x5F594E), dark: NSColor(hex: 0xB5AE9E))
    static let labelMuted = Color(light: NSColor(hex: 0x4A453C), dark: NSColor(hex: 0xD8D3C7))
    static let tagText = Color(light: NSColor(hex: 0x6B655C), dark: NSColor(hex: 0xC7C0B0))
    static let contentBackground = Color(light: NSColor(hex: 0xFBFAF8), dark: NSColor(hex: 0x1C1A17))
    static let dotMuted = Color(light: NSColor(hex: 0xCABFAE), dark: NSColor(hex: 0x55503F))

    static let hoverFill = Color(light: NSColor(white: 0, alpha: 0.055), dark: NSColor(white: 1, alpha: 0.08))
    static let hairline = Color(light: NSColor(white: 0, alpha: 0.07), dark: NSColor(white: 1, alpha: 0.1))
    static let capsuleFill = Color(light: NSColor(white: 0, alpha: 0.05), dark: NSColor(white: 1, alpha: 0.08))

    /// AppKit-side equivalents, for views (like `RichTextEditor`'s `NSTextView`) that need a
    /// genuinely dynamic `NSColor` rather than a bridged SwiftUI `Color`.
    static let inkBodyWriteNSColor = NSColor(light: NSColor(hex: 0x33302A), dark: NSColor(hex: 0xE4E0D8))
    static let accentNSColor = NSColor(light: NSColor(hex: 0xB23A2E), dark: NSColor(hex: 0xE0584A))

    /// Default hex colors for the starter categories seeded into a fresh journal — plain (light-mode)
    /// hex, since user-created/edited categories are a single fixed color rather than a light/dark pair.
    static let defaultCategoryColorHexes = ["B23A2E", "C98A3E", "6F8F6A", "8A7BB0", "5F8AA0"]
}
