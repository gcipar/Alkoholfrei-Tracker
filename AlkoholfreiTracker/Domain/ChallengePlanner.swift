import Foundation

enum ChallengePlanner {
    static func seasonalYear(for kind: GoalKind, today: Date, calendar: Calendar = CivilCalendar.berlin) -> Int {
        let year = calendar.component(.year, from: today)
        let todayStart = calendar.startOfDay(for: today)
        switch kind {
        case .dryJanuary:
            guard
                let end = ChallengeSchedule.dryJanuary(year: year, calendar: calendar)?.endDate,
                todayStart > calendar.startOfDay(for: end)
            else {
                return year
            }
            return year + 1
        case .lent:
            guard
                let end = ChallengeSchedule.lent(year: year, calendar: calendar)?.endDate,
                todayStart > calendar.startOfDay(for: end)
            else {
                return year
            }
            return year + 1
        case .custom, .openEnded:
            return year
        }
    }

    static func suggestedStart(for window: ChallengeWindow, today: Date, calendar: Calendar = CivilCalendar.berlin) -> Date {
        let todayStart = calendar.startOfDay(for: today)
        let start = calendar.startOfDay(for: window.startDate)
        if todayStart < start {
            return start
        }
        if let end = window.endDate, todayStart > calendar.startOfDay(for: end) {
            return start
        }
        return todayStart
    }

    static func window(
        kind: GoalKind,
        today: Date,
        customStart: Date,
        customLength: Int,
        calendar: Calendar = CivilCalendar.berlin
    ) -> ChallengeWindow? {
        switch kind {
        case .dryJanuary:
            return ChallengeSchedule.dryJanuary(
                year: seasonalYear(for: .dryJanuary, today: today, calendar: calendar),
                calendar: calendar
            )
        case .lent:
            return ChallengeSchedule.lent(
                year: seasonalYear(for: .lent, today: today, calendar: calendar),
                calendar: calendar
            )
        case .custom:
            return ChallengeSchedule.custom(start: customStart, lengthDays: customLength, calendar: calendar)
        case .openEnded:
            return ChallengeSchedule.openEnded(start: customStart, calendar: calendar)
        }
    }
}
