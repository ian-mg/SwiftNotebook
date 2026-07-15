import SwiftUI

struct SidebarView: View {
    @Environment(AppState.self) private var appState
    let entries: [JournalEntry]

    private var thisMonthEntries: [JournalEntry] {
        let calendar = Calendar.current
        let now = Date()
        return entries.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
    }

    private var streakSummary: String {
        "\(entries.currentStreak)-day streak · \(entries.totalWords.formatted()) words"
    }

    private var searchResults: [JournalEntry] {
        let query = appState.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return [] }
        return entries.filter { entry in
            entry.title.localizedCaseInsensitiveContains(query)
                || entry.plainText.localizedCaseInsensitiveContains(query)
                || entry.tags.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }

    var body: some View {
        @Bindable var appState = appState

        List {
            if !appState.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Section {
                    if searchResults.isEmpty {
                        Text("No matches")
                            .font(.system(size: 12.5))
                            .foregroundStyle(Palette.inkTertiary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                    } else {
                        ForEach(searchResults) { entry in
                            EntryListRow(
                                entry: entry,
                                isSelected: Calendar.current.isDate(entry.date, inSameDayAs: appState.selectedDate)
                            ) {
                                appState.selectEntry(date: entry.date)
                            }
                        }
                    }
                } header: {
                    Text("RESULTS")
                }
            } else {
                Section {
                    SourceListRow(
                        systemImage: "list.bullet",
                        title: "All Entries",
                        count: entries.count,
                        isSelected: appState.libraryFilter == .all
                    ) {
                        appState.libraryFilter = .all
                    }
                    if appState.libraryFilter == .all {
                        libraryList(entries)
                    }

                    SourceListRow(
                        systemImage: "calendar",
                        title: "This Month",
                        count: thisMonthEntries.count,
                        isSelected: appState.libraryFilter == .thisMonth
                    ) {
                        appState.libraryFilter = .thisMonth
                    }
                    if appState.libraryFilter == .thisMonth {
                        libraryList(thisMonthEntries)
                    }
                } header: {
                    Text("LIBRARY")
                }

                Section {
                    MiniMonthCalendarView(entries: entries)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                } header: {
                    Text("CALENDAR")
                }
            }
        }
        .listStyle(.sidebar)
        .searchable(text: $appState.searchText, placement: .sidebar, prompt: "Search")
        .safeAreaInset(edge: .bottom) {
            Text(streakSummary)
                .font(.system(size: 11.5))
                .foregroundStyle(Palette.inkTertiary)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.bar)
        }
    }

    @ViewBuilder
    private func libraryList(_ list: [JournalEntry]) -> some View {
        if list.isEmpty {
            Text("No entries")
                .font(.system(size: 12.5))
                .foregroundStyle(Palette.inkTertiary)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
        } else {
            ForEach(list.sorted { $0.date > $1.date }) { entry in
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
