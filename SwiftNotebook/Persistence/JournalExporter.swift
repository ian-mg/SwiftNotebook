import AppKit
import UniformTypeIdentifiers

enum ExportFormat {
    case plainText, html, pdf

    var fileExtension: String {
        switch self {
        case .plainText: "txt"
        case .html: "html"
        case .pdf: "pdf"
        }
    }

    var contentType: UTType {
        switch self {
        case .plainText: .plainText
        case .html: .html
        case .pdf: .pdf
        }
    }

    func data(for entries: [JournalEntry]) -> Data? {
        switch self {
        case .plainText: JournalExporter.plainText(entries: entries).data(using: .utf8)
        case .html: JournalExporter.html(entries: entries).data(using: .utf8)
        case .pdf: JournalExporter.pdfData(entries: entries)
        }
    }
}

/// Exports the whole journal to a single file, matching RedNotebook's Journal → Export menu.
enum JournalExporter {
    static func plainText(entries: [JournalEntry]) -> String {
        entries
            .sorted { $0.date < $1.date }
            .map { entry in
                var lines: [String] = [dateHeading(for: entry)]
                if !entry.title.isEmpty {
                    lines.append(entry.title)
                }
                if !entry.tags.isEmpty {
                    lines.append(entry.tags.map { "#\($0)" }.joined(separator: " "))
                }
                lines.append("")
                lines.append(entry.plainText)
                return lines.joined(separator: "\n")
            }
            .joined(separator: "\n\n-----\n\n")
    }

    static func html(entries: [JournalEntry]) -> String {
        let sections = entries
            .sorted { $0.date < $1.date }
            .map { entry -> String in
                let titleHTML = entry.title.isEmpty ? "" : "<h3>\(escapeHTML(entry.title))</h3>\n"
                let tagsHTML = entry.tags.isEmpty ? "" : "<p class=\"tags\">\(escapeHTML(entry.tags.map { "#\($0)" }.joined(separator: " ")))</p>\n"
                return """
                <section>
                <h2>\(escapeHTML(dateHeading(for: entry)))</h2>
                \(titleHTML)\(tagsHTML)\(htmlBodyFragment(entry.attributedBody))
                </section>
                """
            }
            .joined(separator: "\n<hr/>\n")

        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <title>Journal Export</title>
        <style>
        body { font-family: -apple-system, Helvetica, Arial, sans-serif; max-width: 720px; margin: 40px auto; padding: 0 20px; color: #26231E; line-height: 1.6; }
        h2 { color: #B23A2E; margin-top: 0; }
        .tags { color: #6B655C; font-size: 0.9em; }
        hr { border: none; border-top: 1px solid #ddd; margin: 36px 0; }
        </style>
        </head>
        <body>
        \(sections)
        </body>
        </html>
        """
    }

    static func pdfData(entries: [JournalEntry]) -> Data? {
        let combined = NSMutableAttributedString()
        let dateFont = NSFont.boldSystemFont(ofSize: 16)
        let titleFont = NSFont.boldSystemFont(ofSize: 13)
        let tagsFont = NSFont.systemFont(ofSize: 11)

        for entry in entries.sorted(by: { $0.date < $1.date }) {
            combined.append(NSAttributedString(string: dateHeading(for: entry) + "\n", attributes: [.font: dateFont]))
            if !entry.title.isEmpty {
                combined.append(NSAttributedString(string: entry.title + "\n", attributes: [.font: titleFont]))
            }
            if !entry.tags.isEmpty {
                let tagsLine = entry.tags.map { "#\($0)" }.joined(separator: " ")
                combined.append(NSAttributedString(string: tagsLine + "\n", attributes: [.font: tagsFont, .foregroundColor: NSColor.secondaryLabelColor]))
            }
            combined.append(NSAttributedString(string: "\n"))
            combined.append(entry.attributedBody)
            combined.append(NSAttributedString(string: "\n\n\n"))
        }

        return renderPDF(from: combined)
    }

    private static func dateHeading(for entry: JournalEntry) -> String {
        entry.date.formatted(.dateTime.weekday(.wide).month(.wide).day().year())
    }

    private static func escapeHTML(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

    /// `NSAttributedString`'s built-in HTML writer emits a full `<html><body>…</body></html>`
    /// document; extract just the body's inner markup so it can be embedded in our own page.
    private static func htmlBodyFragment(_ attributed: NSAttributedString) -> String {
        guard
            let data = try? attributed.data(
                from: NSRange(location: 0, length: attributed.length),
                documentAttributes: [.documentType: NSAttributedString.DocumentType.html]
            ),
            let htmlString = String(data: data, encoding: .utf8),
            let bodyTagRange = htmlString.range(of: "<body"),
            let bodyOpenEnd = htmlString[bodyTagRange.upperBound...].range(of: ">"),
            let bodyCloseStart = htmlString.range(of: "</body>")
        else {
            return "<p>\(escapeHTML(attributed.string))</p>"
        }
        return String(htmlString[bodyOpenEnd.upperBound..<bodyCloseStart.lowerBound])
    }

    private static func renderPDF(from attributedString: NSAttributedString) -> Data? {
        guard let printInfo = NSPrintInfo.shared.copy() as? NSPrintInfo else { return nil }
        printInfo.topMargin = 48
        printInfo.bottomMargin = 48
        printInfo.leftMargin = 48
        printInfo.rightMargin = 48
        printInfo.horizontalPagination = .fit

        let pageWidth = printInfo.paperSize.width - printInfo.leftMargin - printInfo.rightMargin
        let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: pageWidth, height: 100))
        textView.textContainer?.widthTracksTextView = true
        textView.isEditable = false
        textView.textStorage?.setAttributedString(attributedString)

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".pdf")
        printInfo.jobDisposition = .save
        printInfo.dictionary()[NSPrintInfo.AttributeKey.jobSavingURL] = tempURL

        let operation = NSPrintOperation(view: textView, printInfo: printInfo)
        operation.showsPrintPanel = false
        operation.showsProgressPanel = false
        guard operation.run() else { return nil }

        defer { try? FileManager.default.removeItem(at: tempURL) }
        return try? Data(contentsOf: tempURL)
    }
}
