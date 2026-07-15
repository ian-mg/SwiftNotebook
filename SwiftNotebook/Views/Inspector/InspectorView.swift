import SwiftUI
import AppKit

struct InspectorView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.managedObjectContext) private var context
    let entries: [JournalEntry]

    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Category.nameValue, ascending: true)])
    private var categories: FetchedResults<Category>

    @State private var expandedCategory: UUID?
    @State private var showingNewCategoryAlert = false
    @State private var newCategoryName = ""

    private func entries(in category: Category) -> [JournalEntry] {
        entries.filter { $0.category?.id == category.id }
    }

    /// Frequency across all title/body words (not just hashtags), matching RedNotebook's word
    /// cloud. Tags still carry extra weight and are marked so the cloud can style them distinctly.
    private var wordCloud: [(word: String, count: Int, isTag: Bool)] {
        var counts: [String: Int] = [:]
        var tagWords: Set<String> = []

        for entry in entries {
            for tag in entry.tags {
                let normalized = tag.lowercased()
                counts[normalized, default: 0] += 3
                tagWords.insert(normalized)
            }
            for word in tokenize(entry.title) + tokenize(entry.plainText) {
                counts[word, default: 0] += 1
            }
        }

        return counts
            .sorted { $0.value > $1.value }
            .prefix(40)
            .map { (word: $0.key, count: $0.value, isTag: tagWords.contains($0.key)) }
    }

    private func tokenize(_ text: String) -> [String] {
        text
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count >= 4 && !StopWords.english.contains($0) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        SectionHeader("CATEGORIES")
                        Spacer()
                        Button {
                            newCategoryName = ""
                            showingNewCategoryAlert = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(Palette.inkTertiary)
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, 8)
                    }
                    ForEach(categories) { category in
                        let categoryEntries = entries(in: category)
                        CategoryRow(
                            category: category,
                            count: categoryEntries.count,
                            isExpanded: expandedCategory == category.id
                        ) {
                            expandedCategory = expandedCategory == category.id ? nil : category.id
                        }
                        if expandedCategory == category.id {
                            if categoryEntries.isEmpty {
                                Text("No entries")
                                    .font(.system(size: 12.5))
                                    .foregroundStyle(Palette.inkTertiary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                            } else {
                                ForEach(categoryEntries.sorted { $0.date > $1.date }) { entry in
                                    EntryListRow(
                                        entry: entry,
                                        isSelected: Calendar.current.isDate(entry.date, inSameDayAs: appState.selectedDate)
                                    ) {
                                        appState.selectEntry(date: entry.date)
                                    }
                                    .padding(.leading, 16)
                                }
                            }
                        }
                    }
                }

                Divider().overlay(Palette.hairline)

                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader("FREQUENT WORDS")
                    if wordCloud.isEmpty {
                        Text("No words yet")
                            .font(.system(size: 12.5))
                            .foregroundStyle(Palette.inkTertiary)
                    } else {
                        FlowLayout(horizontalSpacing: 8, verticalSpacing: 6) {
                            ForEach(wordCloud, id: \.word) { entry in
                                WordCloudWord(word: entry.word, count: entry.count, isTag: entry.isTag, maxCount: wordCloud.first?.count ?? 1) {
                                    appState.searchText = entry.word
                                }
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
        .alert("New Category", isPresented: $showingNewCategoryAlert) {
            TextField("Name", text: $newCategoryName)
            Button("Add") {
                addCategory()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func addCategory() {
        let trimmed = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let category = Category(context: context)
        category.id = UUID()
        category.name = trimmed
        category.colorHex = Palette.defaultCategoryColorHexes.randomElement() ?? "8A857C"
        try? context.save()
    }
}

private struct SectionHeader: View {
    let title: String

    init(_ title: String) { self.title = title }

    var body: some View {
        Text(title)
            .font(.system(size: 11, weight: .semibold))
            .tracking(0.3)
            .foregroundStyle(Palette.inkTertiary)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
    }
}

/// Categories behave like folders: tapping one expands it inline to show the entries filed
/// under it, the same way the left sidebar's "All Entries"/"This Month" lists work.
private struct CategoryRow: View {
    @Environment(\.managedObjectContext) private var context
    let category: Category
    let count: Int
    let isExpanded: Bool
    let action: () -> Void

    @State private var isHovering = false
    @State private var showingRenameAlert = false
    @State private var renameText = ""
    @State private var showingColorPicker = false
    @State private var pickedColor: Color = .gray
    @State private var showingDeleteConfirmation = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                Circle().fill(category.color).frame(width: 7, height: 7)
                Text(category.name)
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.ink2621)
                Spacer()
                Text("\(count)")
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.inkTertiary)
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Palette.inkTertiary)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
            }
            .padding(.horizontal, 8)
            .frame(height: 29)
            .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(isHovering ? Palette.hoverFill : .clear))
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .contextMenu {
            Button("Rename…") {
                renameText = category.name
                showingRenameAlert = true
            }
            Button("Change Color…") {
                pickedColor = category.color
                showingColorPicker = true
            }
            Divider()
            Button("Delete…", role: .destructive) {
                showingDeleteConfirmation = true
            }
        }
        .alert("Rename Category", isPresented: $showingRenameAlert) {
            TextField("Name", text: $renameText)
            Button("Save") {
                category.name = renameText
                try? context.save()
            }
            Button("Cancel", role: .cancel) {}
        }
        .popover(isPresented: $showingColorPicker) {
            VStack(spacing: 12) {
                ColorPicker("Category Color", selection: $pickedColor, supportsOpacity: false)
                    .labelsHidden()
                Button("Done") {
                    category.color = pickedColor
                    try? context.save()
                    showingColorPicker = false
                }
            }
            .padding(16)
        }
        .confirmationDialog(
            "Delete this category?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                context.delete(category)
                try? context.save()
            }
        } message: {
            Text("Entries filed under it will keep their content but lose this category.")
        }
    }
}

private struct WordCloudWord: View {
    let word: String
    let count: Int
    let isTag: Bool
    let maxCount: Int
    let action: () -> Void

    private var weight: Double {
        maxCount > 0 ? Double(count) / Double(maxCount) : 0
    }

    private var fontSize: CGFloat {
        13 + (22 - 13) * weight
    }

    var body: some View {
        // Deliberately no underline/link styling — clickable, but reads as plain weighted text
        // like the rest of the cloud, not as a hyperlink.
        Button(action: action) {
            Text(isTag ? "#\(word)" : word)
                .font(.system(size: fontSize, weight: weight > 0.6 ? .semibold : .regular))
                .foregroundStyle(isTag ? Palette.accent.opacity(0.6 + weight * 0.4) : Palette.inkPrimary.opacity(0.4 + weight * 0.6))
        }
        .buttonStyle(.plain)
        .onHover { isHovering in
            if isHovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}
