import Foundation
import SwiftData

enum TrackingStore {
    @MainActor
    static func completeOnboarding(
        context: ModelContext,
        goal: GoalKind,
        startDate: Date,
        window: ChallengeWindow,
        drinks: [DraftDrink],
        now: Date = .now,
        calendar: Calendar = CivilCalendar.berlin
    ) throws {
        let settings = UserSettings(
            onboardingCompleted: true,
            goalKind: goal,
            trackingStartDate: calendar.startOfDay(for: startDate),
            reminderEnabled: false,
            createdAt: now
        )
        context.insert(settings)

        for (index, drink) in drinks.enumerated() {
            guard let stored = drink.stored(sortOrder: index) else { continue }
            context.insert(stored)
        }

        context.insert(ActiveChallenge(window: window))
        try context.save()
        try refreshSnapshot(context: context, now: now, calendar: calendar)
    }

    @MainActor
    static func setToday(
        status: DayStatus,
        context: ModelContext,
        today: Date = .now,
        calendar: Calendar = CivilCalendar.berlin
    ) throws {
        let start = calendar.startOfDay(for: today)
        let logs = try context.fetch(FetchDescriptor<DayLog>())
        if let existing = logs.first(where: { calendar.isDate($0.day, inSameDayAs: start) }) {
            existing.status = status
            existing.day = start
            existing.updatedAt = today
        } else {
            context.insert(DayLog(day: start, status: status, updatedAt: today, calendar: calendar))
        }
        try context.save()
        try syncBadges(context: context, now: today, calendar: calendar)
        try refreshSnapshot(context: context, now: today, calendar: calendar)
    }

    @MainActor
    static func refreshSnapshot(
        context: ModelContext,
        now: Date = .now,
        calendar: Calendar = CivilCalendar.berlin
    ) throws {
        guard let store = WidgetSnapshotStore.live() else { return }
        let summary = try summary(context: context, today: now, calendar: calendar)
        store.save(
            WidgetSnapshot(
                alcoholFreeDays: summary.alcoholFreeDays,
                streakDays: summary.streakDays,
                moneySavedEUR: summary.moneySavedEUR,
                challengeTitle: summary.progress?.title,
                updatedAt: now
            )
        )
    }

    @MainActor
    static func summary(
        context: ModelContext,
        today: Date = .now,
        calendar: Calendar = CivilCalendar.berlin
    ) throws -> HomeSummary {
        let logs = try context.fetch(FetchDescriptor<DayLog>())
        let drinks = try context.fetch(FetchDescriptor<DrinkTemplate>())
        let settings = try context.fetch(FetchDescriptor<UserSettings>())
        let challenges = try context.fetch(FetchDescriptor<ActiveChallenge>())
        let logged = logs.map { LoggedDay(day: $0.day, status: $0.status) }
        let estimates = drinks.map {
            DrinkEstimate(weeklyCount: $0.weeklyCount, priceEUR: $0.priceEUR, kcalPerUnit: $0.kcalPerUnit)
        }
        let trackingStart = settings.first?.trackingStartDate ?? today
        return HomeSummaryBuilder.make(
            logs: logged,
            drinks: estimates,
            window: challenges.first?.window,
            trackingStart: trackingStart,
            today: today,
            calendar: calendar
        )
    }

    @MainActor
    private static func syncBadges(
        context: ModelContext,
        now: Date,
        calendar: Calendar
    ) throws {
        let logs = try context.fetch(FetchDescriptor<DayLog>())
        let logged = logs.map { LoggedDay(day: $0.day, status: $0.status) }
        let total = StreakCalculator.alcoholFreeCount(logged)
        let existing = try context.fetch(FetchDescriptor<BadgeUnlock>())
        let owned = Set(existing.map(\.dayCount))
        for threshold in MilestoneCatalog.unlocked(totalAlcoholFreeDays: total) where !owned.contains(threshold) {
            context.insert(BadgeUnlock(dayCount: threshold, unlockedAt: now))
        }
        try context.save()
    }
}
