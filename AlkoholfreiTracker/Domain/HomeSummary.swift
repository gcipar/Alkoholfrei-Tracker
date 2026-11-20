import Foundation

enum ChallengePhase: Equatable, Sendable {
    case upcoming(start: Date)
    case active(dayIndex: Int, length: Int, freeDays: Int)
    case finished(freeDays: Int, length: Int)
    case openEnded(freeDays: Int, nextMilestone: Int?)
}

struct ChallengeProgress: Equatable, Sendable {
    var title: String
    var fraction: Double
    var phase: ChallengePhase
}

struct HomeSummary: Equatable, Sendable {
    var alcoholFreeDays: Int
    var streakDays: Int
    var moneySavedEUR: Decimal
    var kcalSaved: Double
    var todayStatus: DayStatus?
    var trackingStartsInFuture: Bool
    var trackingStartDate: Date
    var progress: ChallengeProgress?
}

enum HomeSummaryBuilder {
    static func make(
        logs: [LoggedDay],
        drinks: [DrinkEstimate],
        window: ChallengeWindow?,
        trackingStart: Date,
        today: Date,
        calendar: Calendar = CivilCalendar.berlin
    ) -> HomeSummary {
        let alcoholFreeDays = StreakCalculator.alcoholFreeCount(logs)
        let streak = StreakCalculator.currentStreak(logs: logs, today: today, calendar: calendar)
        let todayStart = calendar.startOfDay(for: today)
        let start = calendar.startOfDay(for: trackingStart)
        let todayStatus = logs.first { calendar.isDate($0.day, inSameDayAs: todayStart) }?.status

        return HomeSummary(
            alcoholFreeDays: alcoholFreeDays,
            streakDays: streak,
            moneySavedEUR: SavingsCalculator.moneySaved(drinks: drinks, alcoholFreeDays: alcoholFreeDays),
            kcalSaved: SavingsCalculator.kcalSaved(drinks: drinks, alcoholFreeDays: alcoholFreeDays),
            todayStatus: todayStatus,
            trackingStartsInFuture: todayStart < start,
            trackingStartDate: start,
            progress: window.map { progress(window: $0, logs: logs, today: today, calendar: calendar) }
        )
    }

    static func progress(
        window: ChallengeWindow,
        logs: [LoggedDay],
        today: Date,
        calendar: Calendar = CivilCalendar.berlin
    ) -> ChallengeProgress {
        let todayStart = calendar.startOfDay(for: today)
        let start = calendar.startOfDay(for: window.startDate)
        let freeDays = logs.reduce(into: 0) { count, log in
            let day = calendar.startOfDay(for: log.day)
            guard log.status == .alcoholFree, day >= start else { return }
            if let end = window.endDate {
                guard day <= calendar.startOfDay(for: end) else { return }
            }
            count += 1
        }

        if window.endDate == nil {
            let next = MilestoneCatalog.thresholds.first { $0 > freeDays }
            let previous = MilestoneCatalog.thresholds.last { $0 < freeDays } ?? 0
            let fraction: Double
            if let next, next > previous {
                fraction = Double(freeDays - previous) / Double(next - previous)
            } else {
                fraction = 1
            }
            return ChallengeProgress(
                title: window.title,
                fraction: min(max(fraction, 0), 1),
                phase: .openEnded(freeDays: freeDays, nextMilestone: next)
            )
        }

        guard let length = window.lengthDays(calendar: calendar), length > 0, let end = window.endDate else {
            return ChallengeProgress(title: window.title, fraction: 0, phase: .upcoming(start: start))
        }
        let endDay = calendar.startOfDay(for: end)

        if todayStart < start {
            return ChallengeProgress(title: window.title, fraction: 0, phase: .upcoming(start: start))
        }
        if todayStart > endDay {
            return ChallengeProgress(
                title: window.title,
                fraction: min(Double(freeDays) / Double(length), 1),
                phase: .finished(freeDays: freeDays, length: length)
            )
        }

        let elapsed = CivilCalendar.inclusiveDayCount(from: start, through: todayStart, calendar: calendar) ?? 1
        let dayIndex = min(max(elapsed, 1), length)
        return ChallengeProgress(
            title: window.title,
            fraction: min(Double(freeDays) / Double(length), 1),
            phase: .active(dayIndex: dayIndex, length: length, freeDays: freeDays)
        )
    }
}
