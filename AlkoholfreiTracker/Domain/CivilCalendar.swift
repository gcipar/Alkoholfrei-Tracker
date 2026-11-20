import Foundation

struct CivilDay: Equatable, Sendable {
    var year: Int
    var month: Int
    var day: Int
}

enum CivilCalendar {
    static var berlin: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "de_DE")
        calendar.timeZone = TimeZone(identifier: "Europe/Berlin")
            ?? TimeZone(secondsFromGMT: 3600)
            ?? .current
        calendar.firstWeekday = 2
        calendar.minimumDaysInFirstWeek = 4
        return calendar
    }

    static func date(year: Int, month: Int, day: Int, calendar: Calendar = berlin) -> Date? {
        calendar.date(from: DateComponents(year: year, month: month, day: day))
    }

    static func day(from date: Date, calendar: Calendar = berlin) -> CivilDay? {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        guard let year = components.year, let month = components.month, let day = components.day else {
            return nil
        }
        return CivilDay(year: year, month: month, day: day)
    }

    static func inclusiveDayCount(from start: Date, through end: Date, calendar: Calendar = berlin) -> Int? {
        let startDay = calendar.startOfDay(for: start)
        let endDay = calendar.startOfDay(for: end)
        guard let days = calendar.dateComponents([.day], from: startDay, to: endDay).day else {
            return nil
        }
        return days + 1
    }
}
