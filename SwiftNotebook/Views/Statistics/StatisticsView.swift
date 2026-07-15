import SwiftUI

struct StatisticsView: View {
    @Environment(\.dismiss) private var dismiss
    let entries: [JournalEntry]

    private var longestEntry: JournalEntry? { entries.longestEntry }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Statistics")
                .font(.system(size: 22, weight: .semibold, design: .serif))
                .foregroundStyle(Palette.inkPrimary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatTile(label: "Entries", value: "\(entries.count)")
                StatTile(label: "Total Words", value: entries.totalWords.formatted())
                StatTile(label: "Avg Words / Entry", value: "\(entries.averageWordsPerEntry)")
                StatTile(label: "Current Streak", value: "\(entries.currentStreak) days")
                StatTile(label: "Longest Streak", value: "\(entries.longestStreak) days")
                if let firstEntryDate = entries.firstEntryDate {
                    StatTile(label: "Journaling Since", value: firstEntryDate.formatted(.dateTime.month(.abbreviated).day().year()))
                }
            }

            if let longestEntry {
                Divider().overlay(Palette.hairline)

                VStack(alignment: .leading, spacing: 4) {
                    Text("LONGEST ENTRY")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(0.3)
                        .foregroundStyle(Palette.inkTertiary)
                    Text(longestEntry.title.isEmpty ? "Untitled" : longestEntry.title)
                        .font(.system(size: 15, weight: .medium, design: .serif))
                        .foregroundStyle(Palette.inkPrimary)
                    Text("\(longestEntry.wordCount) words · \(longestEntry.date.formatted(.dateTime.month(.wide).day().year()))")
                        .font(.system(size: 12))
                        .foregroundStyle(Palette.inkSecondary)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(minWidth: 420, minHeight: 380)
        .background(Palette.contentBackground)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
    }
}

private struct StatTile: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .semibold, design: .serif))
                .foregroundStyle(Palette.inkPrimary)
            Text(label.uppercased())
                .font(.system(size: 10.5, weight: .semibold))
                .tracking(0.2)
                .foregroundStyle(Palette.inkTertiary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Palette.capsuleFill))
    }
}
