import Foundation
import Testing
@testable import AlkoholfreiTracker

struct HomeSummaryTests {
    private let calendar = CivilCalendar.berlin

    @Test func slipKeepsAlcoholFreeTotalAndClearsStreak() throws {
        let today = try #require(CivilCalendar.date(year: 2026, month: 1, day: 5))
        let logs = [
            LoggedDay(day: try #require(CivilCalendar.date(year: 2026, month: 1, day: 3)), status: .alcoholFree),
            LoggedDay(day: try #require(CivilCalendar.date(year: 2026, month: 1, day: 4)), status: .alcoholFree),
            LoggedDay(day: today, status: .drank),
        ]
        let window = try #require(ChallengeSchedule.dryJanuary(year: 2026))
        let summary = HomeSummaryBuilder.make(
            logs: logs,
            drinks: [DrinkEstimate(weeklyCount: 7, priceEUR: 2, kcalPerUnit: 100)],
            window: window,
            trackingStart: try #require(CivilCalendar.date(year: 2026, month: 1, day: 1)),
            today: today
        )

        #expect(summary.alcoholFreeDays == 2)
        #expect(summary.streakDays == 0)
        #expect(summary.todayStatus == .drank)
        #expect(summary.moneySavedEUR == 4)
        #expect(summary.progress?.phase == .active(dayIndex: 5, length: 31, freeDays: 2))
    }

    @Test func novemberSelectsNextDryJanuary() throws {
        let today = try #require(CivilCalendar.date(year: 2026, month: 11, day: 20))
        #expect(ChallengePlanner.seasonalYear(for: .dryJanuary, today: today) == 2027)
        let window = try #require(ChallengePlanner.window(kind: .dryJanuary, today: today, customStart: today, customLength: 30))
        #expect(window.year == 2027)
        #expect(calendar.isDate(window.startDate, inSameDayAs: try #require(CivilCalendar.date(year: 2027, month: 1, day: 1))))
    }

    @Test func openGoalShowsNextMilestone() throws {
        let today = try #require(CivilCalendar.date(year: 2026, month: 3, day: 2))
        let start = try #require(CivilCalendar.date(year: 2026, month: 3, day: 1))
        let window = ChallengeSchedule.openEnded(start: start)
        let progress = HomeSummaryBuilder.progress(
            window: window,
            logs: [LoggedDay(day: start, status: .alcoholFree)],
            today: today
        )
        #expect(progress.phase == .openEnded(freeDays: 1, nextMilestone: 7))
    }

    @Test func draftDrinkParsesGermanPrice() {
        let drink = DraftDrink(name: "Bier", weeklyCountText: "7", priceText: "2,50", kcalText: "210")
        let estimate = drink.estimate()
        #expect(estimate?.weeklyCount == 7)
        #expect(estimate?.priceEUR == Decimal(string: "2.50"))
        #expect(estimate?.kcalPerUnit == 210)
    }
}
