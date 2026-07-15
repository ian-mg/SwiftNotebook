import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// A source-list style row matching the sidebar/inspector rows in the design handoff:
/// selected state shows a filled accent pill; unselected rows get a subtle hover fill.
struct SourceListRow: View {
    let systemImage: String
    let title: String
    let count: Int?
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                Image(systemName: systemImage)
                    .font(.system(size: 12))
                    .foregroundStyle(isSelected ? .white : Palette.iconDefault)
                    .frame(width: 16)
                Text(title)
                    .font(.system(size: 13))
                    .foregroundStyle(isSelected ? .white : Palette.labelMuted)
                Spacer()
                if let count {
                    Text("\(count)")
                        .font(.system(size: 12))
                        .foregroundStyle(isSelected ? .white.opacity(0.82) : Palette.inkTertiary)
                }
            }
            .padding(.horizontal, 8)
            .frame(height: 30)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(isSelected ? Palette.accent : (isHovering ? Palette.hoverFill : .clear))
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .listRowInsets(EdgeInsets(top: 1, leading: 0, bottom: 1, trailing: 0))
        .listRowSeparator(.hidden)
    }
}

/// A row for a single entry — used for search results and for expanded library/category lists
/// (the left sidebar's "All Entries"/"This Month", and the inspector's category folders).
struct EntryListRow: View {
    @Environment(\.managedObjectContext) private var context
    let entry: JournalEntry
    let isSelected: Bool
    let action: () -> Void

    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Category.nameValue, ascending: true)])
    private var categories: FetchedResults<Category>

    @State private var isHovering = false
    @State private var showingRenameAlert = false
    @State private var renameText = ""
    @State private var showingDeleteConfirmation = false

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title.isEmpty ? "Untitled" : entry.title)
                    .font(.system(size: 13))
                    .foregroundStyle(isSelected ? .white : Palette.labelMuted)
                    .lineLimit(1)
                Text(entry.date.formatted(.dateTime.month(.abbreviated).day().year()))
                    .font(.system(size: 11))
                    .foregroundStyle(isSelected ? .white.opacity(0.82) : Palette.inkTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(isSelected ? Palette.accent : (isHovering ? Palette.hoverFill : .clear))
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .listRowInsets(EdgeInsets(top: 1, leading: 0, bottom: 1, trailing: 0))
        .listRowSeparator(.hidden)
        .contextMenu {
            Button("Rename…") {
                renameText = entry.title
                showingRenameAlert = true
            }
            Button("Copy as Plain Text") {
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(entry.plainText, forType: .string)
            }
            Menu("File Under") {
                ForEach(categories) { category in
                    Button {
                        entry.category = category
                        save()
                    } label: {
                        if entry.category?.id == category.id {
                            Label(category.name, systemImage: "checkmark")
                        } else {
                            Text(category.name)
                        }
                    }
                }
                if entry.category != nil {
                    Divider()
                    Button("None") {
                        entry.category = nil
                        save()
                    }
                }
            }
            Button("Duplicate") {
                duplicateEntry()
            }
            Menu("Export") {
                Button("As Plain Text…") { export(.plainText) }
                Button("As HTML…") { export(.html) }
                Button("As PDF…") { export(.pdf) }
            }
            Divider()
            Button("Delete…", role: .destructive) {
                showingDeleteConfirmation = true
            }
        }
        .alert("Rename Entry", isPresented: $showingRenameAlert) {
            TextField("Title", text: $renameText)
            Button("Save") {
                entry.title = renameText
                save()
            }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog(
            "Delete this entry?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                context.delete(entry)
                try? context.save()
            }
        } message: {
            Text("This can't be undone.")
        }
    }

    private func save() {
        entry.modifiedAt = .now
        try? context.save()
    }

    private func duplicateEntry() {
        let copy = JournalEntry(context: context)
        copy.id = UUID()
        copy.date = entry.date
        copy.title = entry.title
        copy.attributedBody = entry.attributedBody
        copy.tagsRaw = entry.tagsRaw
        copy.category = entry.category
        copy.createdAt = .now
        copy.modifiedAt = .now
        try? context.save()
    }

    private func export(_ format: ExportFormat) {
        let panel = NSSavePanel()
        panel.title = "Export Entry"
        panel.nameFieldStringValue = "\(entry.date.formatted(.dateTime.year().month().day())).\(format.fileExtension)"
        panel.allowedContentTypes = [format.contentType]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        guard let data = format.data(for: [entry]) else { return }
        try? data.write(to: url)
    }
}
