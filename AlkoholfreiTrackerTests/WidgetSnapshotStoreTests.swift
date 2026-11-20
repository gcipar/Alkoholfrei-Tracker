import Foundation
import Testing
@testable import AlkoholfreiTracker

struct WidgetSnapshotStoreTests {
    @Test func roundTripKeepsMoneyAndStreak() throws {
        let suiteName = "test.alkoholfrei.snapshot.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = WidgetSnapshotStore(defaults: defaults)
        let snapshot = WidgetSnapshot(
            alcoholFreeDays: 12,
            streakDays: 4,
            moneySavedEUR: Decimal(string: "24.50", locale: Locale(identifier: "en_US_POSIX")) ?? 0,
            challengeTitle: "Dry January",
            updatedAt: try #require(CivilCalendar.date(year: 2026, month: 1, day: 12))
        )

        store.save(snapshot)
        let loaded = try #require(store.load())
        #expect(loaded.alcoholFreeDays == 12)
        #expect(loaded.streakDays == 4)
        #expect(loaded.moneySavedEUR == snapshot.moneySavedEUR)
        #expect(loaded.challengeTitle == "Dry January")
    }
}
