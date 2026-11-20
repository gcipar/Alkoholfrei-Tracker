import Foundation
import Testing
@testable import AlkoholfreiTracker

struct MilestoneCatalogTests {
    @Test func sevenDayBadgeStaysAfterASlip() throws {
        let calendar = CivilCalendar.berlin
        var logs: [LoggedDay] = []
        for offset in 0..<7 {
            let day = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 1 + offset)))
            logs.append(LoggedDay(day: day, status: .alcoholFree))
        }
        let slipDay = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 8)))
        logs.append(LoggedDay(day: slipDay, status: .drank))

        let total = StreakCalculator.alcoholFreeCount(logs)
        #expect(total == 7)
        #expect(StreakCalculator.currentStreak(logs: logs, today: slipDay, calendar: calendar) == 0)
        #expect(MilestoneCatalog.unlocked(totalAlcoholFreeDays: total) == [1, 7])
    }

    @Test func gardenStagesFollowTotalDays() {
        #expect(MilestoneCatalog.stage(for: 0) == .seed)
        #expect(MilestoneCatalog.stage(for: 1) == .sprout)
        #expect(MilestoneCatalog.stage(for: 7) == .youngPlant)
        #expect(MilestoneCatalog.stage(for: 14) == .plant)
        #expect(MilestoneCatalog.stage(for: 31) == .bush)
        #expect(MilestoneCatalog.stage(for: 100) == .tree)
    }
}
