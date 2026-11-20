import Foundation
import Testing
@testable import AlkoholfreiTracker

struct StreakCalculatorTests {
    private let calendar = CivilCalendar.berlin

    @Test func slipResetsStreakAndKeepsTotal() throws {
        let logs = try days([
            (2026, 3, 1, DayStatus.alcoholFree),
            (2026, 3, 2, .alcoholFree),
            (2026, 3, 3, .alcoholFree),
            (2026, 3, 4, .drank),
        ])
        let today = try date(2026, 3, 4)

        #expect(StreakCalculator.alcoholFreeCount(logs) == 3)
        #expect(StreakCalculator.currentStreak(logs: logs, today: today, calendar: calendar) == 0)
    }

    @Test func openTodayKeepsStreakThroughYesterday() throws {
        let logs = try days([
            (2026, 3, 2, .alcoholFree),
            (2026, 3, 3, .alcoholFree),
        ])
        let today = try date(2026, 3, 4)

        #expect(StreakCalculator.currentStreak(logs: logs, today: today, calendar: calendar) == 2)
    }

    @Test func missingDayEndsTheRun() throws {
        let logs = try days([
            (2026, 3, 1, .alcoholFree),
            (2026, 3, 2, .alcoholFree),
            (2026, 3, 4, .alcoholFree),
        ])
        let today = try date(2026, 3, 4)

        #expect(StreakCalculator.currentStreak(logs: logs, today: today, calendar: calendar) == 1)
    }

    @Test func gapBeforeYesterdayDoesNotKeepAnOlderRun() throws {
        let logs = try days([
            (2026, 3, 1, .alcoholFree),
            (2026, 3, 2, .alcoholFree),
        ])
        let today = try date(2026, 3, 5)

        #expect(StreakCalculator.currentStreak(logs: logs, today: today, calendar: calendar) == 0)
    }

    @Test func todayAlcoholFreeContinuesTheRun() throws {
        let logs = try days([
            (2026, 3, 3, .drank),
            (2026, 3, 4, .alcoholFree),
            (2026, 3, 5, .alcoholFree),
        ])
        let today = try date(2026, 3, 5)

        #expect(StreakCalculator.alcoholFreeCount(logs) == 2)
        #expect(StreakCalculator.currentStreak(logs: logs, today: today, calendar: calendar) == 2)
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) throws -> Date {
        try #require(calendar.date(from: DateComponents(year: year, month: month, day: day)))
    }

    private func days(_ values: [(Int, Int, Int, DayStatus)]) throws -> [LoggedDay] {
        try values.map { year, month, day, status in
            LoggedDay(day: try date(year, month, day), status: status)
        }
    }
}
