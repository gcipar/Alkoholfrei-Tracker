import SwiftData
import Testing
@testable import AlkoholfreiTracker

struct ModelStoreTests {
    @Test func inMemoryStoreKeepsADayLog() throws {
        let container = try AppModelContainer.make(inMemory: true)
        let context = ModelContext(container)
        let day = try #require(CivilCalendar.date(year: 2026, month: 1, day: 3))
        context.insert(DayLog(day: day, status: .alcoholFree))
        try context.save()

        let logs = try context.fetch(FetchDescriptor<DayLog>())
        #expect(logs.count == 1)
        #expect(logs.first?.status == .alcoholFree)
        #expect(CivilCalendar.day(from: try #require(logs.first).day) == CivilDay(year: 2026, month: 1, day: 3))
    }

    @Test func challengeWindowRoundTripsThroughTheModel() throws {
        let window = try #require(ChallengeSchedule.lent(year: 2027))
        let container = try AppModelContainer.make(inMemory: true)
        let context = ModelContext(container)
        context.insert(ActiveChallenge(window: window))
        try context.save()

        let stored = try #require(try context.fetch(FetchDescriptor<ActiveChallenge>()).first)
        #expect(stored.window == window)
    }
}
