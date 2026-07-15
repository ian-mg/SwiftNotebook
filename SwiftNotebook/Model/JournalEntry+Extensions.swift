import Foundation
import AppKit

// Core Data always generates Optional properties for String/Date/UUID attributes,
// even when marked non-optional in the model (the "optional" flag only affects
// save-time validation). These wrappers give the rest of the app non-optional access.
extension JournalEntry {
    public var id: UUID {
        get { idValue ?? UUID() }
        set { idValue = newValue }
    }

    var date: Date {
        get { dateValue ?? .now }
        set { dateValue = newValue }
    }

    var title: String {
        get { titleValue ?? "" }
        set { titleValue = newValue }
    }

    /// Default font for body text — used whenever a run doesn't carry an explicit font.
    static let defaultBodyFont = NSFont.serifSystemFont(ofSize: 18.5)

    /// The entry body as real rich text (`NSTextView`/`NSAttributedString`, the same mechanism
    /// TextEdit and Notes use), stored as RTF data — a portable, user-inspectable format rather
    /// than a proprietary blob.
    var attributedBody: NSAttributedString {
        get {
            guard let data = bodyRTFDataValue, !data.isEmpty,
                  let attributed = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil)
            else {
                return NSAttributedString(string: "")
            }
            return attributed
        }
        set {
            let fullRange = NSRange(location: 0, length: newValue.length)
            bodyRTFDataValue = try? newValue.data(from: fullRange, documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf])
        }
    }

    /// Plain-text projection of `attributedBody`, used for word counts, search, and blank checks.
    var plainText: String {
        attributedBody.string
    }

    var tagsRaw: String {
        get { tagsRawValue ?? "" }
        set { tagsRawValue = newValue }
    }

    var createdAt: Date {
        get { createdAtValue ?? .now }
        set { createdAtValue = newValue }
    }

    var modifiedAt: Date {
        get { modifiedAtValue ?? .now }
        set { modifiedAtValue = newValue }
    }

    var tags: [String] {
        get {
            tagsRaw
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
        }
        set {
            tagsRaw = newValue.joined(separator: ",")
        }
    }

    var wordCount: Int {
        plainText
            .split(whereSeparator: { $0.isWhitespace || $0.isNewline })
            .filter { !$0.isEmpty }
            .count
    }

    var isBlank: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && plainText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && tagsRaw.isEmpty
    }
}
