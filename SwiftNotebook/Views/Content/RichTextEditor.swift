import SwiftUI
import AppKit

/// A genuine rich-text editor backed by `NSTextView`/`NSAttributedString` — the same mechanism
/// TextEdit, Mail, and Notes have used for real bold/italic since long before SwiftUI existed.
/// Toolbar buttons trigger formatting via the standard AppKit responder chain (`NSApp.sendAction`),
/// the same way a Format menu's Bold command reaches whichever text view is first responder.
final class RichTextView: NSTextView {
    @objc func toggleBoldTrait(_ sender: Any?) {
        toggleTrait(.boldFontMask)
    }

    @objc func toggleItalicTrait(_ sender: Any?) {
        toggleTrait(.italicFontMask)
    }

    @objc func insertRichLink(_ sender: Any?) {
        guard let textStorage else { return }
        let range = selectedRange()
        guard range.length > 0 else { return }
        textStorage.beginEditing()
        textStorage.addAttribute(.link, value: URL(string: "https://")!, range: range)
        textStorage.endEditing()
        didChangeText()
    }

    private func toggleTrait(_ trait: NSFontTraitMask) {
        guard let textStorage else { return }
        let range = selectedRange()
        guard range.length > 0 else { return }
        let fontManager = NSFontManager.shared

        textStorage.beginEditing()
        textStorage.enumerateAttribute(.font, in: range, options: []) { value, subrange, _ in
            let currentFont = (value as? NSFont) ?? JournalEntry.defaultBodyFont
            let newFont = fontManager.traits(of: currentFont).contains(trait)
                ? fontManager.convert(currentFont, toNotHaveTrait: trait)
                : fontManager.convert(currentFont, toHaveTrait: trait)
            textStorage.addAttribute(.font, value: newFont, range: subrange)
        }
        textStorage.endEditing()
        didChangeText()
    }
}

struct RichTextEditor: NSViewRepresentable {
    @Binding var attributedText: NSAttributedString
    var defaultFont: NSFont
    var textColor: NSColor
    var lineSpacing: CGFloat
    /// Called when the user clicks a date cross-reference (a `2026-07-01`-style date typed
    /// anywhere in the text, auto-linked to jump to that day — RedNotebook's `[YYYY-MM-DD]` links).
    var onDateLinkTapped: ((Date) -> Void)? = nil

    /// Wrapping the text view in a real `NSScrollView` (rather than sizing it to its content and
    /// letting an outer SwiftUI `ScrollView` do the scrolling) is what gives us the standard
    /// "caret stays on screen while typing" behavior for free — `NSTextView` calls
    /// `scrollRangeToVisible` on its enclosing scroll view automatically as you type. Without a
    /// real enclosing `NSScrollView`, there's nothing for that call to reach, so pressing Return
    /// at the bottom of the visible area would move the caret off-screen with no auto-scroll.
    func makeNSView(context: Context) -> NSScrollView {
        let textView = RichTextView()
        textView.delegate = context.coordinator
        textView.isRichText = true
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.drawsBackground = false
        textView.textContainerInset = .zero
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainer?.widthTracksTextView = true
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.isContinuousSpellCheckingEnabled = true
        textView.isGrammarCheckingEnabled = true
        textView.font = defaultFont
        textView.typingAttributes = typingAttributes
        textView.textStorage?.setAttributedString(attributedText)
        // RTF only preserves a static RGB snapshot of the text color, so anything reloaded from
        // storage would otherwise stay locked to whichever appearance was active when it was last
        // saved. Re-stamping with the live dynamic NSColor here (not a resolved value) keeps it
        // adapting correctly on future light/dark switches.
        textView.textColor = textColor
        if let textStorage = textView.textStorage {
            context.coordinator.linkifyDates(in: textStorage)
        }

        let scrollView = NSScrollView()
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.autohidesScrollers = true
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? RichTextView else { return }

        // `makeCoordinator()` only runs once for this view's lifetime, but `updateNSView` runs
        // every time the caller passes a new entry's binding (e.g. switching entries) — without
        // refreshing these, `textDidChange` would keep writing keystrokes into whichever entry's
        // binding the coordinator was first created with, silently corrupting it.
        context.coordinator.attributedText = $attributedText
        context.coordinator.onDateLinkTapped = onDateLinkTapped

        guard textView.textStorage?.string != attributedText.string else { return }
        let selectedRanges = textView.selectedRanges
        textView.textStorage?.setAttributedString(attributedText)
        textView.textColor = textColor
        if let textStorage = textView.textStorage {
            context.coordinator.linkifyDates(in: textStorage)
        }
        textView.selectedRanges = selectedRanges
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(attributedText: $attributedText, onDateLinkTapped: onDateLinkTapped)
    }

    private var typingAttributes: [NSAttributedString.Key: Any] {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = lineSpacing
        return [.font: defaultFont, .foregroundColor: textColor, .paragraphStyle: style]
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var attributedText: Binding<NSAttributedString>
        var onDateLinkTapped: ((Date) -> Void)?

        private static let dateLinkScheme = "swiftnotebook"
        private static let datePattern = try! NSRegularExpression(pattern: #"\[?(\d{4}-\d{2}-\d{2})\]?"#)
        private static let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.timeZone = .current
            formatter.locale = Locale(identifier: "en_US_POSIX")
            return formatter
        }()

        init(attributedText: Binding<NSAttributedString>, onDateLinkTapped: ((Date) -> Void)?) {
            self.attributedText = attributedText
            self.onDateLinkTapped = onDateLinkTapped
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView, let textStorage = textView.textStorage else { return }
            linkifyDates(in: textStorage)
            attributedText.wrappedValue = textView.attributedString()
        }

        func textView(_ textView: NSTextView, clickedOnLink link: Any, at charIndex: Int) -> Bool {
            guard let url = link as? URL, url.scheme == Self.dateLinkScheme,
                  let dateString = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "date" })?.value,
                  let date = Self.dateFormatter.date(from: dateString)
            else {
                return false
            }
            onDateLinkTapped?(date)
            return true
        }

        /// Recognizes `2026-07-01`-style (optionally `[bracketed]`) date references anywhere in
        /// the text and turns them into clickable links to that day — RedNotebook's cross-reference
        /// feature, minus the markdown brackets since this is rich text.
        func linkifyDates(in textStorage: NSTextStorage) {
            let text = textStorage.string
            let fullRange = NSRange(location: 0, length: (text as NSString).length)
            guard Self.datePattern.firstMatch(in: text, range: fullRange) != nil else { return }

            textStorage.beginEditing()
            Self.datePattern.enumerateMatches(in: text, range: fullRange) { match, _, _ in
                guard let match, let dateRange = Range(match.range(at: 1), in: text) else { return }
                let dateString = String(text[dateRange])
                guard Self.dateFormatter.date(from: dateString) != nil else { return }
                guard var components = URLComponents(string: "\(Self.dateLinkScheme)://entry") else { return }
                components.queryItems = [URLQueryItem(name: "date", value: dateString)]
                guard let url = components.url else { return }

                textStorage.addAttribute(.link, value: url, range: match.range)
                textStorage.addAttribute(.foregroundColor, value: Palette.accentNSColor, range: match.range)
                textStorage.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: match.range)
            }
            textStorage.endEditing()
        }
    }
}
