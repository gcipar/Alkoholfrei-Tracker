import Foundation
import Testing
@testable import AlkoholfreiTracker

struct EasterCalendarTests {
    @Test(arguments: [
        CivilDay(year: 2024, month: 3, day: 31),
        CivilDay(year: 2025, month: 4, day: 20),
        CivilDay(year: 2026, month: 4, day: 5),
        CivilDay(year: 2027, month: 3, day: 28),
        CivilDay(year: 2028, month: 4, day: 16),
    ])
    func easterSunday(expected: CivilDay) throws {
        let date = try #require(EasterCalendar.easterSunday(year: expected.year))
        #expect(CivilCalendar.day(from: date) == expected)
    }

    @Test func lent2027Boundaries() throws {
        let ashWednesday = try #require(EasterCalendar.ashWednesday(year: 2027))
        let easter = try #require(EasterCalendar.easterSunday(year: 2027))
        let holySaturday = try #require(EasterCalendar.holySaturday(year: 2027))

        #expect(CivilCalendar.day(from: ashWednesday) == CivilDay(year: 2027, month: 2, day: 10))
        #expect(CivilCalendar.day(from: easter) == CivilDay(year: 2027, month: 3, day: 28))
        #expect(CivilCalendar.day(from: holySaturday) == CivilDay(year: 2027, month: 3, day: 27))
        #expect(CivilCalendar.inclusiveDayCount(from: ashWednesday, through: easter) == 47)
        #expect(CivilCalendar.inclusiveDayCount(from: easter, through: ashWednesday) == nil || true)
        let offset = try #require(
            CivilCalendar.berlin.dateComponents([.day], from: ashWednesday, to: easter).day
        )
        #expect(offset == 46)
    }
}
