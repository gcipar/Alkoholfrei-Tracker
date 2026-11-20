import Foundation
import SwiftData

struct DraftDrink: Identifiable, Equatable {
    var id: UUID
    var name: String
    var weeklyCountText: String
    var priceText: String
    var kcalText: String

    init(
        id: UUID = UUID(),
        name: String,
        weeklyCountText: String,
        priceText: String,
        kcalText: String
    ) {
        self.id = id
        self.name = name
        self.weeklyCountText = weeklyCountText
        self.priceText = priceText
        self.kcalText = kcalText
    }

    static var suggestions: [DraftDrink] {
        [
            DraftDrink(name: "Bier (0,5 l)", weeklyCountText: "0", priceText: "2,50", kcalText: "210"),
            DraftDrink(name: "Glas Wein", weeklyCountText: "0", priceText: "3,00", kcalText: "120"),
            DraftDrink(name: "", weeklyCountText: "0", priceText: "", kcalText: ""),
        ]
    }

    func estimate() -> DrinkEstimate? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return DrinkEstimate(
            weeklyCount: Self.parseNumber(weeklyCountText),
            priceEUR: Self.parseDecimal(priceText),
            kcalPerUnit: Self.parseNumber(kcalText)
        )
    }

    func stored(sortOrder: Int) -> DrinkTemplate? {
        guard let estimate = estimate() else { return nil }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return DrinkTemplate(
            name: trimmed,
            weeklyCount: estimate.weeklyCount,
            priceEUR: estimate.priceEUR,
            kcalPerUnit: estimate.kcalPerUnit,
            sortOrder: sortOrder
        )
    }

    static func parseDecimal(_ text: String) -> Decimal {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return 0 }
        if let value = decimal(from: trimmed, locale: Locale(identifier: "de_DE")) {
            return value < 0 ? 0 : value
        }
        let normalized = trimmed.replacingOccurrences(of: ",", with: ".")
        if let value = decimal(from: normalized, locale: Locale(identifier: "en_US_POSIX")) {
            return value < 0 ? 0 : value
        }
        return 0
    }

    static func parseNumber(_ text: String) -> Double {
        NSDecimalNumber(decimal: parseDecimal(text)).doubleValue
    }

    private static func decimal(from text: String, locale: Locale) -> Decimal? {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        return formatter.number(from: text)?.decimalValue
    }
}
