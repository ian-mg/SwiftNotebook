import SwiftUI
import AppKit
import CoreData

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.managedObjectContext) private var context

    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \JournalEntry.dateValue, ascending: false)])
    private var entries: FetchedResults<JournalEntry>

    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \EntryTemplate.nameValue, ascending: true)])
    private var templates: FetchedResults<EntryTemplate>

    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var currentEntry: JournalEntry?
    /// All entries sharing the selected date, in creation order — RedNotebook allows more than
    /// one titled section per day, so a day isn't limited to a single entry.
    @State private var dayEntries: [JournalEntry] = []
    @State private var showingDeleteConfirmation = false
    @State private var showingTemplatesSheet = false
    @State private var showingStatisticsSheet = false

    var body: some View {
        @Bindable var appState = appState

        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(entries: Array(entries))
                .navigationSplitViewColumnWidth(252)
        } detail: {
            Group {
                if let currentEntry {
                    EntryDetailView(entry: currentEntry)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Palette.contentBackground)
            .toolbar { toolbarContent }
            .navigationTitle(dayTitle)
            .inspector(isPresented: $appState.inspectorVisible) {
                InspectorView(entries: Array(entries))
                    .navigationSplitViewColumnWidth(236)
            }
        }
        .onAppear { syncEntry() }
        .onChange(of: appState.selectedDate) { _, _ in syncEntry() }
        .confirmationDialog(
            "Delete this entry?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Entry", role: .destructive) {
                deleteCurrentEntry()
            }
        } message: {
            Text("This can't be undone.")
        }
        .sheet(isPresented: $showingTemplatesSheet) {
            TemplatesView()
        }
        .sheet(isPresented: $showingStatisticsSheet) {
            StatisticsView(entries: Array(entries))
        }
    }

    private var dayTitle: String {
        appState.selectedDate.formatted(.dateTime.weekday(.wide).month().day())
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigation) {
            Button {
                appState.selectEntry(date: .now)
            } label: {
                Label("New Entry", systemImage: "square.and.pencil")
            }
        }

        ToolbarItemGroup(placement: .navigation) {
            Button {
                appState.step(by: -1)
            } label: {
                Image(systemName: "chevron.left")
            }
            Button {
                appState.step(by: 1)
            } label: {
                Image(systemName: "chevron.right")
            }
        }

        if dayEntries.count > 1 {
            ToolbarItem {
                Menu {
                    ForEach(Array(dayEntries.enumerated()), id: \.element.id) { index, sectionEntry in
                        Button {
                            currentEntry = sectionEntry
                        } label: {
                            let label = sectionEntry.title.isEmpty ? "Section \(index + 1)" : sectionEntry.title
                            if sectionEntry === currentEntry {
                                Label(label, systemImage: "checkmark")
                            } else {
                                Text(label)
                            }
                        }
                    }
                } label: {
                    if let currentEntry, let index = dayEntries.firstIndex(where: { $0 === currentEntry }) {
                        Text("Section \(index + 1) of \(dayEntries.count)")
                    }
                }
            }
        }

        ToolbarItem {
            Button {
                addSection()
            } label: {
                Image(systemName: "plus.square.on.square")
            }
        }

        ToolbarItem {
            Menu {
                let manualTemplates = templates.filter { $0.weekday == nil }
                if manualTemplates.isEmpty {
                    Text("No templates yet")
                } else {
                    ForEach(manualTemplates) { template in
                        Button(template.name.isEmpty ? "Untitled Template" : template.name) {
                            insertTemplate(template)
                        }
                    }
                }
                Divider()
                Button("Manage Templates…") {
                    showingTemplatesSheet = true
                }
            } label: {
                Image(systemName: "richtext.page")
            }
        }

        ToolbarItem {
            Button {
                showingStatisticsSheet = true
            } label: {
                Image(systemName: "chart.bar")
            }
        }

        ToolbarItem {
            Button(role: .destructive) {
                showingDeleteConfirmation = true
            } label: {
                Image(systemName: "trash")
            }
            .disabled(currentEntry == nil)
        }

        ToolbarItem(placement: .primaryAction) {
            Menu {
                Button("Export as Plain Text…") { exportJournal(as: .plainText) }
                Button("Export as HTML…") { exportJournal(as: .html) }
                Button("Export as PDF…") { exportJournal(as: .pdf) }
            } label: {
                Image(systemName: "square.and.arrow.up")
            }
        }

        ToolbarItem(placement: .primaryAction) {
            Button {
                appState.inspectorVisible.toggle()
            } label: {
                Image(systemName: "sidebar.right")
            }
        }
    }

    /// Matches whatever's currently selected in the sidebar: a specific entry (calendar day,
    /// search result, or a library-list row) when `libraryFilter` is nil, or the full "All
    /// Entries"/"This Month" list when one of those is active.
    private var exportScope: (entries: [JournalEntry], suggestedName: String) {
        switch appState.libraryFilter {
        case .all:
            return (Array(entries), "Journal")
        case .thisMonth:
            let calendar = Calendar.current
            let now = Date()
            let monthEntries = entries.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
            return (monthEntries, now.formatted(.dateTime.month(.wide).year()))
        case nil:
            guard let currentEntry else { return ([], "Entry") }
            return ([currentEntry], currentEntry.date.formatted(.dateTime.year().month().day()))
        }
    }

    private func exportJournal(as format: ExportFormat) {
        let scope = exportScope
        let panel = NSSavePanel()
        panel.title = "Export Journal"
        panel.nameFieldStringValue = "\(scope.suggestedName).\(format.fileExtension)"
        panel.allowedContentTypes = [format.contentType]

        guard panel.runModal() == .OK, let url = panel.url else { return }
        guard let data = format.data(for: scope.entries) else { return }
        try? data.write(to: url)
    }

    private func syncEntry() {
        let day = Calendar.current.startOfDay(for: appState.selectedDate)
        let dayMatches = entries
            .filter { Calendar.current.isDate($0.date, inSameDayAs: day) }
            .sorted { $0.createdAt < $1.createdAt }

        if let old = currentEntry, !dayMatches.contains(where: { $0 === old }), old.isInserted, old.isBlank {
            context.delete(old)
        }

        if !dayMatches.isEmpty {
            dayEntries = dayMatches
            if currentEntry == nil || !dayMatches.contains(where: { $0 === currentEntry }) {
                currentEntry = dayMatches.first
            }
        } else {
            let entry = JournalEntry(context: context)
            entry.id = UUID()
            entry.date = day
            entry.title = ""
            let weekday = Calendar.current.component(.weekday, from: day)
            if let dailyTemplate = templates.first(where: { $0.weekday == weekday }) {
                entry.attributedBody = dailyTemplate.attributedBody
            } else {
                entry.attributedBody = NSAttributedString(string: "")
            }
            entry.tagsRaw = ""
            entry.createdAt = .now
            entry.modifiedAt = .now
            dayEntries = [entry]
            currentEntry = entry
        }
    }

    private func addSection() {
        let day = Calendar.current.startOfDay(for: appState.selectedDate)
        let entry = JournalEntry(context: context)
        entry.id = UUID()
        entry.date = day
        entry.title = ""
        entry.attributedBody = NSAttributedString(string: "")
        entry.tagsRaw = ""
        entry.createdAt = .now
        entry.modifiedAt = .now
        dayEntries.append(entry)
        currentEntry = entry
    }

    private func insertTemplate(_ template: EntryTemplate) {
        guard let entry = currentEntry else { return }
        let combined = NSMutableAttributedString(attributedString: entry.attributedBody)
        if combined.length > 0 {
            combined.append(NSAttributedString(string: "\n\n"))
        }
        combined.append(template.attributedBody)
        entry.attributedBody = combined
        entry.modifiedAt = .now
        try? context.save()
    }

    private func deleteCurrentEntry() {
        guard let entry = currentEntry else { return }
        context.delete(entry)
        try? context.save()
        syncEntry()
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environment(AppState())
}
