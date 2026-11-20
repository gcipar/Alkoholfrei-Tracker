import Foundation
import Testing
@testable import AlkoholfreiTracker

struct SavingsCalculatorTests {
    @Test func sevenBeersAtTwoEuroSaveTwoEuroPerDay() {
        let drinks = [DrinkEstimate(weeklyCount: 7, priceEUR: Decimal(2), kcalPerUnit: 210)]
        #expect(SavingsCalculator.dailyMoney(drinks: drinks) == 2)
        #expect(SavingsCalculator.moneySaved(drinks: drinks, alcoholFreeDays: 3) == 6)
        #expect(SavingsCalculator.dailyKcal(drinks: drinks) == 210)
        #expect(SavingsCalculator.kcalSaved(drinks: drinks, alcoholFreeDays: 3) == 630)
    }

    @Test func weekAndMonthGroupAlcoholFreeDays() throws {
        let calendar = CivilCalendar.berlin
        let first = try #require(CivilCalendar.date(year: 2027, month: 3, day: 1))
        let second = try #require(CivilCalendar.date(year: 2027, month: 3, day: 2))
        let nextWeek = try #require(CivilCalendar.date(year: 2027, month: 3, day: 8))
        let drinks = [DrinkEstimate(weeklyCount: 7, priceEUR: Decimal(2), kcalPerUnit: 0)]

        let weeks = SavingsCalculator.byWeek(
            alcoholFreeDays: [first, second, nextWeek],
            drinks: drinks,
            calendar: calendar
        )
        #expect(weeks.count == 2)
        #expect(weeks[0].alcoholFreeDays == 2)
        #expect(weeks[0].moneyEUR == 4)
        #expect(weeks[1].alcoholFreeDays == 1)
        #expect(weeks[1].moneyEUR == 2)

        let months = SavingsCalculator.byMonth(
            alcoholFreeDays: [first, second, nextWeek],
            drinks: drinks,
            calendar: calendar
        )
        #expect(months.count == 1)
        #expect(months[0].alcoholFreeDays == 3)
        #expect(months[0].moneyEUR == 6)
    }
}
