import Foundation

enum StreakCalculator {
    static func alcoholFreeCount(_ logs: [LoggedDay]) -> Int {
        logs.reduce(into: 0) { count, log in
            if log.status == .alcoholFree {
                count += 1
            }
        }
    }

    /// Consecutive alcohol-free logs ending today, or ending yesterday when today has no log.
    /// A logged drink or a missing day ends the run. Today logged as a drink returns 0.
    static func currentStreak(logs: [LoggedDay], today: Date, calendar: Calendar = CivilCalendar.berlin) -> Int {
        let todayStart = calendar.startOfDay(for: today)
        var byDay: [Date: DayStatus] = [:]
        for log in logs {
            byDay[calendar.startOfDay(for: log.day)] = log.status
        }

        let anchor: Date
        if let todayStatus = byDay[todayStart] {
            if todayStatus == .drank {
                return 0
            }
            anchor = todayStart
        } else {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: todayStart) else {
                return 0
            }
            anchor = yesterday
        }

        var streak = 0
        var cursor = anchor
        while let status = byDay[cursor] {
            guard status == .alcoholFree else { break }
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return streak
    }
}
