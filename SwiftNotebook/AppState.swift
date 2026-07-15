import Foundation
import Observation

enum LibraryFilter {
    case all
    case thisMonth
}

@Observable
final class AppState {
    var selectedDate: Date
    /// `nil` means the user has drilled into one specific entry (via the calendar, search, or a
    /// library list row) — used both to highlight the right sidebar row and to decide export scope
    /// (a single entry vs. the whole "All Entries"/"This Month" list).
    var libraryFilter: LibraryFilter?
    var sidebarVisible = true
    var inspectorVisible = true
    var searchText = ""
    var lastSavedAt: Date?

    init(selectedDate: Date = Calendar.current.startOfDay(for: .now)) {
        self.selectedDate = selectedDate
    }

    func step(by days: Int) {
        guard let newDate = Calendar.current.date(byAdding: .day, value: days, to: selectedDate) else { return }
        selectedDate = Calendar.current.startOfDay(for: newDate)
        libraryFilter = nil
    }

    func selectEntry(date: Date) {
        selectedDate = Calendar.current.startOfDay(for: date)
        libraryFilter = nil
    }
}
