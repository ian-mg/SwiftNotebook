import SwiftUI
import CoreData

/// Manage entry templates — one per weekday (applied automatically to new blank entries) plus
/// arbitrary named templates (inserted manually), matching RedNotebook's template system.
struct TemplatesView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \EntryTemplate.nameValue, ascending: true)])
    private var templates: FetchedResults<EntryTemplate>

    @State private var selectedTemplate: EntryTemplate?

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedTemplate) {
                ForEach(templates) { template in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(template.name.isEmpty ? "Untitled Template" : template.name)
                        Text(template.weekdayLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .tag(template)
                }
                .onDelete(perform: deleteTemplates)
            }
            .navigationSplitViewColumnWidth(200)
            .toolbar {
                ToolbarItem {
                    Button {
                        addTemplate()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem {
                    Button(role: .destructive) {
                        deleteSelectedTemplate()
                    } label: {
                        Image(systemName: "trash")
                    }
                    .disabled(selectedTemplate == nil)
                }
            }
        } detail: {
            if let selectedTemplate {
                TemplateEditorView(template: selectedTemplate)
            } else {
                Text("Select or create a template")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("Templates")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
        .frame(minWidth: 640, minHeight: 420)
    }

    private func addTemplate() {
        let template = EntryTemplate(context: context)
        template.id = UUID()
        template.name = "New Template"
        template.weekday = nil
        template.attributedBody = NSAttributedString(string: "")
        try? context.save()
        selectedTemplate = template
    }

    private func deleteTemplates(at offsets: IndexSet) {
        for index in offsets {
            context.delete(templates[index])
        }
        try? context.save()
    }

    private func deleteSelectedTemplate() {
        guard let selectedTemplate else { return }
        context.delete(selectedTemplate)
        self.selectedTemplate = nil
        try? context.save()
    }
}

private struct TemplateEditorView: View {
    @Environment(\.managedObjectContext) private var context
    @ObservedObject var template: EntryTemplate

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Template name", text: Binding(
                get: { template.name },
                set: { template.name = $0; save() }
            ))
            .textFieldStyle(.roundedBorder)
            .font(.title3)

            Picker("Applies to", selection: Binding(
                get: { template.weekday ?? 0 },
                set: { template.weekday = $0 == 0 ? nil : $0; save() }
            )) {
                Text("Manual (insert on demand)").tag(0)
                ForEach(1...7, id: \.self) { weekday in
                    Text(Calendar.current.weekdaySymbols[weekday - 1]).tag(weekday)
                }
            }
            .pickerStyle(.menu)

            Text("Body")
                .font(.caption)
                .foregroundStyle(.secondary)

            RichTextEditor(
                attributedText: Binding(
                    get: { template.attributedBody },
                    set: { template.attributedBody = $0; save() }
                ),
                defaultFont: JournalEntry.defaultBodyFont,
                textColor: Palette.inkBodyWriteNSColor,
                lineSpacing: 6
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(8)
            .background(RoundedRectangle(cornerRadius: 8).fill(Palette.capsuleFill))
        }
        .padding(20)
    }

    private func save() {
        try? context.save()
    }
}
