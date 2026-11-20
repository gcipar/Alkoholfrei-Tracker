import Foundation

@Observable
final class OnboardingModel {
    var step = 0
    var goalKind: GoalKind = .dryJanuary
    var customLength = 30
    var startDate: Date
    var drinks: [DraftDrink]

    private let today: Date
    private let calendar: Calendar
    private var didEditStartDate = false

    init(today: Date = .now, calendar: Calendar = CivilCalendar.berlin) {
        self.today = today
        self.calendar = calendar
        self.startDate = calendar.startOfDay(for: today)
        self.drinks = DraftDrink.suggestions
        if let window = ChallengePlanner.window(
            kind: .dryJanuary,
            today: today,
            customStart: today,
            customLength: 30,
            calendar: calendar
        ) {
            startDate = ChallengePlanner.suggestedStart(for: window, today: today, calendar: calendar)
        }
    }

    var seasonalPreview: ChallengeWindow? {
        switch goalKind {
        case .dryJanuary, .lent:
            return ChallengePlanner.window(
                kind: goalKind,
                today: today,
                customStart: startDate,
                customLength: customLength,
                calendar: calendar
            )
        case .custom, .openEnded:
            return nil
        }
    }

    func select(_ kind: GoalKind) {
        goalKind = kind
        guard !didEditStartDate else { return }
        guard let window = ChallengePlanner.window(
            kind: kind,
            today: today,
            customStart: calendar.startOfDay(for: today),
            customLength: customLength,
            calendar: calendar
        ) else {
            return
        }
        startDate = ChallengePlanner.suggestedStart(for: window, today: today, calendar: calendar)
    }

    func updateStartDate(_ date: Date) {
        didEditStartDate = true
        startDate = calendar.startOfDay(for: date)
    }

    func resolvedWindow() -> ChallengeWindow? {
        let length = min(max(customLength, 1), 366)
        customLength = length
        return ChallengePlanner.window(
            kind: goalKind,
            today: today,
            customStart: startDate,
            customLength: length,
            calendar: calendar
        )
    }

    func addDrink() {
        drinks.append(DraftDrink(name: "", weeklyCountText: "0", priceText: "", kcalText: ""))
    }

    func removeDrinks(at offsets: IndexSet) {
        drinks.remove(atOffsets: offsets)
    }
}
