import SwiftUI

struct MiniMonthCalendarView: View {
    @Environment(AppState.self) private var appState
    let entries: [JournalEntry]

    @State private var displayedMonth: Date = Calendar.current.startOfDay(for: .now)

    private let calendar = Calendar.current
    private let weekdaySymbols = ["S", "M", "T", "W", "T", "F", "S"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)

    private var entryDays: Set<Date> {
        Set(entries.map { calendar.startOfDay(for: $0.date) })
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text(displayedMonth.formatted(.dateTime.month(.wide).year()))
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(Palette.ink2621)
                Spacer()
                Button {
                    shiftMonth(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.plain)
                .foregroundStyle(Palette.inkTertiary)
                Button {
                    shiftMonth(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(.plain)
                .foregroundStyle(Palette.inkTertiary)
            }

            HStack(spacing: 0) {
                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Palette.weekdayLetter)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(Array(daysInGrid().enumerated()), id: \.offset) { _, day in
                    if let day {
                        DayCell(
                            day: day,
                            hasEntry: entryDays.contains(calendar.startOfDay(for: day)),
                            isSelected: calendar.isDate(day, inSameDayAs: appState.selectedDate),
                            isToday: calendar.isDateInToday(day)
                        ) {
                            appState.selectEntry(date: day)
                        }
                    } else {
                        Color.clear.frame(width: 28, height: 28)
                    }
                }
            }
        }
        .padding(.horizontal, 4)
        .onAppear {
            displayedMonth = calendar.startOfDay(for: appState.selectedDate)
        }
    }

    private func shiftMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
            displayedMonth = newMonth
        }
    }

    private func daysInGrid() -> [Date?] {
        guard
            let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth),
            let range = calendar.range(of: .day, in: .month, for: displayedMonth)
        else { return [] }

        let firstWeekday = calendar.component(.weekday, from: monthInterval.start)
        let leadingBlanks = firstWeekday - calendar.firstWeekday
        var days: [Date?] = Array(repeating: nil, count: max(0, leadingBlanks))

        for offset in range {
            if let date = calendar.date(byAdding: .day, value: offset - 1, to: monthInterval.start) {
                days.append(date)
            }
        }
        return days
    }
}

private struct DayCell: View {
    let day: Date
    let hasEntry: Bool
    let isSelected: Bool
    let isToday: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if isSelected {
                    Circle().fill(Palette.accent)
                } else if isToday {
                    Circle().strokeBorder(Palette.accent.opacity(0.5), lineWidth: 1.5)
                }

                Text("\(Calendar.current.component(.day, from: day))")
                    .font(.system(size: 12, weight: isSelected ? .semibold : (hasEntry ? .medium : .regular)))
                    .foregroundStyle(dayTextColor)

                if hasEntry, !isSelected {
                    VStack {
                        Spacer()
                        Circle()
                            .fill(Palette.accent)
                            .frame(width: 4, height: 4)
                            .padding(.bottom, 3)
                    }
                }
            }
            .frame(width: 28, height: 28)
        }
        .buttonStyle(.plain)
    }

    private var dayTextColor: Color {
        if isSelected { return .white }
        if hasEntry { return Palette.ink2621 }
        return Palette.inkQuaternary
    }
}
