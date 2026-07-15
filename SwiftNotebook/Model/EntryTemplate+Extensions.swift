import Foundation
import AppKit

extension EntryTemplate {
    public var id: UUID {
        get { idValue ?? UUID() }
        set { idValue = newValue }
    }

    var name: String {
        get { nameValue ?? "" }
        set { nameValue = newValue }
    }

    /// 1–7 for Sunday–Saturday (matching `Calendar.component(.weekday, from:)`), or `nil` for a
    /// named template the user inserts manually rather than one applied automatically by weekday.
    var weekday: Int? {
        get { weekdayValue == 0 ? nil : Int(weekdayValue) }
        set { weekdayValue = Int16(newValue ?? 0) }
    }

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

    static let weekdaySymbols = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var weekdayLabel: String {
        guard let weekday, (1...7).contains(weekday) else { return "Manual" }
        return Self.weekdaySymbols[weekday - 1]
    }
}
