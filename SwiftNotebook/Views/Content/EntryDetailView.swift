import SwiftUI
import AppKit
import CoreData

private enum EntryFocusField: Hashable {
    case title
    case body
}

struct EntryDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.managedObjectContext) private var context
    @ObservedObject var entry: JournalEntry
    @State private var newTagText = ""
    @FocusState private var focusedField: EntryFocusField?

    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Category.nameValue, ascending: true)])
    private var categories: FetchedResults<Category>

    var body: some View {
        VStack(spacing: 0) {
            // Fixed header (title/meta/tags) — not scrolled, so the body editor below can own its
            // own native scrolling (see RichTextEditor) and keep the caret on screen while typing.
            VStack(alignment: .leading, spacing: 0) {
                TextField("Untitled", text: Binding(
                    get: { entry.title },
                    set: { entry.title = $0; save() }
                ))
                .textFieldStyle(.plain)
                .font(.system(size: 31, weight: .medium, design: .serif))
                .foregroundStyle(Palette.inkPrimary)
                .focused($focusedField, equals: .title)
                .onSubmit {
                    focusedField = .body
                }

                HStack(spacing: 6) {
                    Text(entry.date.formatted(.dateTime.weekday(.wide).month().day().year()))
                    Circle().fill(Palette.dotMuted).frame(width: 3, height: 3)
                    Text("\(entry.wordCount) words")
                }
                .font(.system(size: 12.5))
                .foregroundStyle(Palette.inkSecondary)
                .padding(.top, 6)

                FlowLayout(horizontalSpacing: 7, verticalSpacing: 7) {
                    ForEach(entry.tags, id: \.self) { tag in
                        EditableTagCapsule(text: tag) {
                            removeTag(tag)
                        }
                    }
                    if let category = entry.category {
                        CategoryCapsule(category: category) {
                            entry.category = nil
                            save()
                        }
                    }
                    TextField("+ tag", text: $newTagText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11.5))
                        .foregroundStyle(Palette.tagText)
                        .frame(width: 64)
                        .onSubmit { addTag() }
                    Menu {
                        ForEach(categories) { category in
                            Button {
                                entry.category = category
                                save()
                            } label: {
                                Text(category.name)
                            }
                        }
                        if entry.category != nil {
                            Divider()
                            Button("Remove Category", role: .destructive) {
                                entry.category = nil
                                save()
                            }
                        }
                    } label: {
                        Text("+ category")
                            .font(.system(size: 11.5))
                            .foregroundStyle(Palette.tagText)
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()
                }
                .padding(.top, 14)

                Divider()
                    .overlay(Palette.hairline)
                    .padding(.top, 26)
                    .padding(.bottom, 26)
            }
            .padding(.top, 36)
            .padding(.horizontal, 48)

            RichTextEditor(
                attributedText: attributedBodyBinding,
                defaultFont: JournalEntry.defaultBodyFont,
                textColor: Palette.inkBodyWriteNSColor,
                lineSpacing: 13,
                onDateLinkTapped: { date in
                    appState.selectEntry(date: date)
                }
            )
            .padding(.horizontal, 48)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .focused($focusedField, equals: .body)

            statusBar
        }
        .toolbar {
            ToolbarItemGroup {
                Button {
                    sendFormatAction(#selector(RichTextView.toggleBoldTrait(_:)))
                } label: {
                    Text("B").fontWeight(.semibold)
                }
                .keyboardShortcut("b", modifiers: .command)
                Button {
                    sendFormatAction(#selector(RichTextView.toggleItalicTrait(_:)))
                } label: {
                    Text("I").italic()
                }
                .keyboardShortcut("i", modifiers: .command)
                Button {
                    sendFormatAction(#selector(RichTextView.insertRichLink(_:)))
                } label: {
                    Image(systemName: "link")
                }
            }
        }
    }

    private var attributedBodyBinding: Binding<NSAttributedString> {
        Binding(
            get: { entry.attributedBody },
            set: { entry.attributedBody = $0; save() }
        )
    }

    private func sendFormatAction(_ selector: Selector) {
        NSApp.sendAction(selector, to: nil, from: nil)
    }

    private var statusBar: some View {
        HStack(spacing: 6) {
            Text("\(entry.wordCount) words")
            Circle().fill(Palette.dotMuted).frame(width: 3, height: 3)
            if let lastSavedAt = appState.lastSavedAt {
                Text("Saved \(lastSavedAt.formatted(.relative(presentation: .named)))")
                    .foregroundStyle(Palette.inkSecondary)
            } else {
                Text("Not yet saved")
                    .foregroundStyle(Palette.inkSecondary)
            }
            Spacer()
            Text("Autosave on")
        }
        .font(.system(size: 11.5))
        .foregroundStyle(Palette.inkTertiary)
        .padding(.horizontal, 22)
        .frame(height: 32)
        .overlay(alignment: .top) {
            Rectangle().fill(Palette.hairline).frame(height: 1)
        }
    }

    private func save() {
        entry.modifiedAt = .now
        do {
            try context.save()
            appState.lastSavedAt = .now
        } catch {
            assertionFailure("Failed to save entry: \(error)")
        }
    }

    private func addTag() {
        let cleaned = newTagText
            .trimmingCharacters(in: .whitespaces)
            .trimmingCharacters(in: CharacterSet(charactersIn: "#"))
            .lowercased()
        newTagText = ""
        guard !cleaned.isEmpty, !entry.tags.contains(cleaned) else { return }
        entry.tags.append(cleaned)
        save()
    }

    private func removeTag(_ tag: String) {
        entry.tags.removeAll { $0 == tag }
        save()
    }
}

private struct EditableTagCapsule: View {
    let text: String
    let onRemove: () -> Void
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 4) {
            Text("#\(text)")
                .font(.system(size: 11.5))
                .foregroundStyle(Palette.tagText)
            if isHovering {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Palette.inkTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 11)
        .frame(height: 24)
        .background(Capsule().fill(Palette.capsuleFill))
        .onHover { isHovering = $0 }
    }
}

private struct CategoryCapsule: View {
    let category: Category
    let onRemove: () -> Void
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 5) {
            Circle().fill(category.color).frame(width: 6, height: 6)
            Text(category.name)
                .font(.system(size: 11.5))
                .foregroundStyle(Palette.tagText)
            if isHovering {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Palette.inkTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 11)
        .frame(height: 24)
        .background(Capsule().fill(Palette.capsuleFill))
        .onHover { isHovering = $0 }
    }
}
