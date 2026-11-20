import Foundation

struct CalendarDay: Equatable, Identifiable, Sendable {
    var date: Date
    var status: DayStatus?

    var id: Date { date }
}

struct MonthGrid: Equatable, Sendable {
    var monthStart: Date
    var weekdaySymbols: [String]
    var weeks: [[CalendarDay?]]

    var alcoholFreeDays: Int {
        weeks.flatMap { $0 }.compactMap { $0 }.reduce(into: 0) { count, day in
            if day.status == .alcoholFree {
                count += 1
            }
        }
    }
}

enum MonthCalendarBuilder {
    static func grid(
        containing date: Date,
        logs: [LoggedDay],
        calendar: Calendar = CivilCalendar.berlin
    ) -> MonthGrid? {
        guard let interval = calendar.dateInterval(of: .month, for: date) else { return nil }
        let monthStart = interval.start
        var statusByDay: [Date: DayStatus] = [:]
        for log in logs {
            statusByDay[calendar.startOfDay(for: log.day)] = log.status
        }

        let weekday = calendar.component(.weekday, from: monthStart)
        let leading = (weekday - calendar.firstWeekday + 7) % 7
        var cells: [CalendarDay?] = Array(repeating: nil, count: leading)
        var cursor = monthStart
        while cursor < interval.end {
            cells.append(CalendarDay(date: cursor, status: statusByDay[cursor]))
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        let trailing = (7 - (cells.count % 7)) % 7
        cells.append(contentsOf: Array(repeating: nil, count: trailing))

        var weeks: [[CalendarDay?]] = []
        var index = 0
        while index < cells.count {
            let end = min(index + 7, cells.count)
            weeks.append(Array(cells[index..<end]))
            index = end
        }

        return MonthGrid(
            monthStart: monthStart,
            weekdaySymbols: orderedWeekdaySymbols(calendar: calendar),
            weeks: weeks
        )
    }

    static func shiftMonth(from date: Date, by months: Int, calendar: Calendar = CivilCalendar.berlin) -> Date? {
        calendar.date(byAdding: .month, value: months, to: calendar.startOfDay(for: date))
    }

    private static func orderedWeekdaySymbols(calendar: Calendar) -> [String] {
        let symbols = calendar.veryShortWeekdaySymbols
        guard !symbols.isEmpty else { return [] }
        let start = calendar.firstWeekday - 1
        return (0..<symbols.count).map { symbols[(start + $0) % symbols.count] }
    }
}
