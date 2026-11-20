import Foundation

/// Gregorian Easter Sunday using the Meeus/Jones/Butcher algorithm.
enum EasterCalendar {
    static func easterSunday(year: Int, calendar: Calendar = CivilCalendar.berlin) -> Date? {
        guard year >= 1583 else { return nil }

        let yearNumber = year
        let a = yearNumber % 19
        let b = yearNumber / 100
        let c = yearNumber % 100
        let d = b / 4
        let e = b % 4
        let f = (b + 8) / 25
        let g = (b - f + 1) / 3
        let h = (19 * a + b - d - g + 15) % 30
        let i = c / 4
        let k = c % 4
        let l = (32 + 2 * e + 2 * i - h - k) % 7
        let m = (a + 11 * h + 22 * l) / 451
        let month = (h + l - 7 * m + 114) / 31
        let day = ((h + l - 7 * m + 114) % 31) + 1

        return calendar.date(from: DateComponents(year: yearNumber, month: month, day: day))
    }

    static func ashWednesday(year: Int, calendar: Calendar = CivilCalendar.berlin) -> Date? {
        guard let easter = easterSunday(year: year, calendar: calendar) else { return nil }
        return calendar.date(byAdding: .day, value: -46, to: easter)
    }

    static func holySaturday(year: Int, calendar: Calendar = CivilCalendar.berlin) -> Date? {
        guard let easter = easterSunday(year: year, calendar: calendar) else { return nil }
        return calendar.date(byAdding: .day, value: -1, to: easter)
    }
}
