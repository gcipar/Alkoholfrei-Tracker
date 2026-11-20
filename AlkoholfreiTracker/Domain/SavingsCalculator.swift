import Foundation

struct DrinkEstimate: Equatable, Sendable {
    var weeklyCount: Double
    var priceEUR: Decimal
    var kcalPerUnit: Double
}

struct PeriodSavings: Equatable, Sendable {
    var periodStart: Date
    var alcoholFreeDays: Int
    var moneyEUR: Decimal
    var kcal: Double
}

enum SavingsCalculator {
    static func weeklyMoney(drinks: [DrinkEstimate]) -> Decimal {
        drinks.reduce(Decimal(0)) { sum, drink in
            sum + Decimal(drink.weeklyCount) * drink.priceEUR
        }
    }

    static func weeklyKcal(drinks: [DrinkEstimate]) -> Double {
        drinks.reduce(0) { sum, drink in
            sum + (drink.weeklyCount * drink.kcalPerUnit)
        }
    }

    static func dailyMoney(drinks: [DrinkEstimate]) -> Decimal {
        weeklyMoney(drinks: drinks) / Decimal(7)
    }

    static func dailyKcal(drinks: [DrinkEstimate]) -> Double {
        weeklyKcal(drinks: drinks) / 7
    }

    static func moneySaved(drinks: [DrinkEstimate], alcoholFreeDays: Int) -> Decimal {
        dailyMoney(drinks: drinks) * Decimal(max(alcoholFreeDays, 0))
    }

    static func kcalSaved(drinks: [DrinkEstimate], alcoholFreeDays: Int) -> Double {
        dailyKcal(drinks: drinks) * Double(max(alcoholFreeDays, 0))
    }

    static func byWeek(
        alcoholFreeDays: [Date],
        drinks: [DrinkEstimate],
        calendar: Calendar = CivilCalendar.berlin
    ) -> [PeriodSavings] {
        grouped(alcoholFreeDays: alcoholFreeDays, drinks: drinks, component: .weekOfYear, calendar: calendar)
    }

    static func byMonth(
        alcoholFreeDays: [Date],
        drinks: [DrinkEstimate],
        calendar: Calendar = CivilCalendar.berlin
    ) -> [PeriodSavings] {
        grouped(alcoholFreeDays: alcoholFreeDays, drinks: drinks, component: .month, calendar: calendar)
    }

    private static func grouped(
        alcoholFreeDays: [Date],
        drinks: [DrinkEstimate],
        component: Calendar.Component,
        calendar: Calendar
    ) -> [PeriodSavings] {
        let moneyPerDay = dailyMoney(drinks: drinks)
        let kcalPerDay = dailyKcal(drinks: drinks)
        var counts: [Date: Int] = [:]

        for day in alcoholFreeDays {
            guard let interval = calendar.dateInterval(of: component, for: day) else { continue }
            counts[interval.start, default: 0] += 1
        }

        return counts.keys.sorted().map { start in
            let count = counts[start, default: 0]
            return PeriodSavings(
                periodStart: start,
                alcoholFreeDays: count,
                moneyEUR: moneyPerDay * Decimal(count),
                kcal: kcalPerDay * Double(count)
            )
        }
    }
}
