import Foundation
import Testing
@testable import AlkoholfreiTracker

struct MonthCalendarTests {
    @Test func november2026StartsOnSundayAfterSixBlanks() throws {
        let date = try #require(CivilCalendar.date(year: 2026, month: 11, day: 20))
        let logged = LoggedDay(day: try #require(CivilCalendar.date(year: 2026, month: 11, day: 2)), status: .alcoholFree)
        let grid = try #require(MonthCalendarBuilder.grid(containing: date, logs: [logged]))

        let firstWeek = try #require(grid.weeks.first)
        #expect(firstWeek[0] == nil)
        #expect(firstWeek[5] == nil)
        let firstOfMonth = try #require(firstWeek[6])
        #expect(CivilCalendar.day(from: firstOfMonth.date) == CivilDay(year: 2026, month: 11, day: 1))
        #expect(grid.alcoholFreeDays == 1)
        #expect(grid.weeks.allSatisfy { $0.count == 7 })
    }
}
