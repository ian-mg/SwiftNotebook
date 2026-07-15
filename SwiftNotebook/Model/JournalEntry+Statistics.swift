import Foundation

extension Array where Element == JournalEntry {
    private var entryDays: Set<Date> {
        Set(map { Calendar.current.startOfDay(for: $0.date) })
    }

    /// Consecutive days with an entry, counting backward from today.
    var currentStreak: Int {
        let days = entryDays
        let calendar = Calendar.current
        var day = calendar.startOfDay(for: .now)
        var streak = 0
        while days.contains(day) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return streak
    }

    /// The longest run of consecutive days with an entry, anywhere in the journal's history.
    var longestStreak: Int {
        let sortedDays = entryDays.sorted()
        guard !sortedDays.isEmpty else { return 0 }
        let calendar = Calendar.current

        var longest = 1
        var current = 1
        for index in 1..<sortedDays.count {
            let previousDayPlusOne = calendar.date(byAdding: .day, value: 1, to: sortedDays[index - 1])
            if let previousDayPlusOne, calendar.isDate(sortedDays[index], inSameDayAs: previousDayPlusOne) {
                current += 1
                longest = Swift.max(longest, current)
            } else {
                current = 1
            }
        }
        return longest
    }

    var totalWords: Int {
        reduce(0) { $0 + $1.wordCount }
    }

    var averageWordsPerEntry: Int {
        isEmpty ? 0 : totalWords / count
    }

    var longestEntry: JournalEntry? {
        self.max { $0.wordCount < $1.wordCount }
    }

    var firstEntryDate: Date? {
        map(\.date).min()
    }
}
