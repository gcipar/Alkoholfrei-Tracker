import Foundation
import Testing
@testable import AlkoholfreiTracker

struct ChallengeScheduleTests {
    @Test func dryJanuary2026IsThirtyOneDays() throws {
        let window = try #require(ChallengeSchedule.dryJanuary(year: 2026))
        #expect(CivilCalendar.day(from: window.startDate) == CivilDay(year: 2026, month: 1, day: 1))
        let end = try #require(window.endDate)
        #expect(CivilCalendar.day(from: end) == CivilDay(year: 2026, month: 1, day: 31))
        #expect(window.lengthDays() == 31)
        #expect(window.kind == .dryJanuary)
    }

    @Test func lent2027RunsAshWednesdayThroughHolySaturday() throws {
        let window = try #require(ChallengeSchedule.lent(year: 2027))
        #expect(CivilCalendar.day(from: window.startDate) == CivilDay(year: 2027, month: 2, day: 10))
        let end = try #require(window.endDate)
        #expect(CivilCalendar.day(from: end) == CivilDay(year: 2027, month: 3, day: 27))
        #expect(window.lengthDays() == 46)
        #expect(window.year == 2027)
    }

    @Test func customLengthIsInclusive() throws {
        let start = try #require(CivilCalendar.date(year: 2026, month: 5, day: 1))
        let window = try #require(ChallengeSchedule.custom(start: start, lengthDays: 10))
        #expect(window.lengthDays() == 10)
        let end = try #require(window.endDate)
        #expect(CivilCalendar.day(from: end) == CivilDay(year: 2026, month: 5, day: 10))
    }

    @Test func customRejectsEmptyLength() throws {
        let start = try #require(CivilCalendar.date(year: 2026, month: 5, day: 1))
        #expect(ChallengeSchedule.custom(start: start, lengthDays: 0) == nil)
    }

    @Test func openEndedHasNoEnd() throws {
        let start = try #require(CivilCalendar.date(year: 2026, month: 6, day: 2))
        let window = ChallengeSchedule.openEnded(start: start)
        #expect(window.endDate == nil)
        #expect(window.lengthDays() == nil)
        #expect(window.kind == .openEnded)
    }
}
