import AppKit

extension NSFont {
    static func serifSystemFont(ofSize size: CGFloat, weight: NSFont.Weight = .regular) -> NSFont {
        let base = NSFont.systemFont(ofSize: size, weight: weight)
        guard let descriptor = base.fontDescriptor.withDesign(.serif), let serifFont = NSFont(descriptor: descriptor, size: size) else {
            return base
        }
        return serifFont
    }
}
