import Foundation
import SwiftData

@Model
final class UserSettings {
    var id: UUID
    var onboardingCompleted: Bool
    var goalKindRaw: String
    var trackingStartDate: Date
    var reminderEnabled: Bool
    var reminderHour: Int
    var reminderMinute: Int
    var createdAt: Date

    init(
        id: UUID = UUID(),
        onboardingCompleted: Bool = false,
        goalKind: GoalKind = .openEnded,
        trackingStartDate: Date = .now,
        reminderEnabled: Bool = false,
        reminderHour: Int = 20,
        reminderMinute: Int = 0,
        createdAt: Date = .now
    ) {
        self.id = id
        self.onboardingCompleted = onboardingCompleted
        self.goalKindRaw = goalKind.rawValue
        self.trackingStartDate = trackingStartDate
        self.reminderEnabled = reminderEnabled
        self.reminderHour = min(max(reminderHour, 0), 23)
        self.reminderMinute = min(max(reminderMinute, 0), 59)
        self.createdAt = createdAt
    }

    var goalKind: GoalKind {
        get { GoalKind(rawValue: goalKindRaw) ?? .openEnded }
        set { goalKindRaw = newValue.rawValue }
    }
}

@Model
final class DrinkTemplate {
    var id: UUID
    var name: String
    var weeklyCount: Double
    var priceEUR: Decimal
    var kcalPerUnit: Double
    var sortOrder: Int

    init(
        id: UUID = UUID(),
        name: String,
        weeklyCount: Double,
        priceEUR: Decimal,
        kcalPerUnit: Double,
        sortOrder: Int
    ) {
        self.id = id
        self.name = name
        self.weeklyCount = max(weeklyCount, 0)
        self.priceEUR = priceEUR < 0 ? 0 : priceEUR
        self.kcalPerUnit = max(kcalPerUnit, 0)
        self.sortOrder = sortOrder
    }
}

@Model
final class DayLog {
    var id: UUID
    var day: Date
    var statusRaw: String
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        day: Date,
        status: DayStatus,
        updatedAt: Date = .now,
        calendar: Calendar = CivilCalendar.berlin
    ) {
        self.id = id
        self.day = calendar.startOfDay(for: day)
        self.statusRaw = status.rawValue
        self.updatedAt = updatedAt
    }

    var status: DayStatus {
        get { DayStatus(rawValue: statusRaw) ?? .alcoholFree }
        set { statusRaw = newValue.rawValue }
    }
}

@Model
final class ActiveChallenge {
    var id: UUID
    var kindRaw: String
    var title: String
    var startDate: Date
    var endDate: Date?
    var year: Int?

    init(id: UUID = UUID(), window: ChallengeWindow) {
        self.id = id
        self.kindRaw = window.kind.rawValue
        self.title = window.title
        self.startDate = window.startDate
        self.endDate = window.endDate
        self.year = window.year
    }

    var kind: GoalKind {
        get { GoalKind(rawValue: kindRaw) ?? .custom }
        set { kindRaw = newValue.rawValue }
    }

    var window: ChallengeWindow {
        ChallengeWindow(
            kind: kind,
            title: title,
            startDate: startDate,
            endDate: endDate,
            year: year
        )
    }
}

@Model
final class BadgeUnlock {
    var id: UUID
    var dayCount: Int
    var unlockedAt: Date

    init(id: UUID = UUID(), dayCount: Int, unlockedAt: Date = .now) {
        self.id = id
        self.dayCount = dayCount
        self.unlockedAt = unlockedAt
    }
}
