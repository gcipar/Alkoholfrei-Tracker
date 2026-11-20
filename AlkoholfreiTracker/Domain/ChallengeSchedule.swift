import Foundation

struct ChallengeWindow: Equatable, Sendable {
    var kind: GoalKind
    var title: String
    var startDate: Date
    var endDate: Date?
    var year: Int?

    func lengthDays(calendar: Calendar = CivilCalendar.berlin) -> Int? {
        guard let endDate else { return nil }
        return CivilCalendar.inclusiveDayCount(from: startDate, through: endDate, calendar: calendar)
    }
}

enum ChallengeSchedule {
    static func dryJanuary(year: Int, calendar: Calendar = CivilCalendar.berlin) -> ChallengeWindow? {
        guard
            let start = calendar.date(from: DateComponents(year: year, month: 1, day: 1)),
            let end = calendar.date(from: DateComponents(year: year, month: 1, day: 31))
        else {
            return nil
        }
        return ChallengeWindow(
            kind: .dryJanuary,
            title: "Dry January",
            startDate: start,
            endDate: end,
            year: year
        )
    }

    static func lent(year: Int, calendar: Calendar = CivilCalendar.berlin) -> ChallengeWindow? {
        guard
            let start = EasterCalendar.ashWednesday(year: year, calendar: calendar),
            let end = EasterCalendar.holySaturday(year: year, calendar: calendar)
        else {
            return nil
        }
        return ChallengeWindow(
            kind: .lent,
            title: "Fastenzeit",
            startDate: start,
            endDate: end,
            year: year
        )
    }

    static func custom(start: Date, lengthDays: Int, calendar: Calendar = CivilCalendar.berlin) -> ChallengeWindow? {
        guard lengthDays > 0 else { return nil }
        let startDay = calendar.startOfDay(for: start)
        guard let end = calendar.date(byAdding: .day, value: lengthDays - 1, to: startDay) else {
            return nil
        }
        return ChallengeWindow(
            kind: .custom,
            title: "Eigenes Ziel",
            startDate: startDay,
            endDate: end,
            year: nil
        )
    }

    static func openEnded(start: Date, calendar: Calendar = CivilCalendar.berlin) -> ChallengeWindow {
        ChallengeWindow(
            kind: .openEnded,
            title: "Eigenes Ziel",
            startDate: calendar.startOfDay(for: start),
            endDate: nil,
            year: nil
        )
    }
}
