import Foundation
import SwiftData

enum AppModelContainer {
    static let schema = Schema([
        UserSettings.self,
        DrinkTemplate.self,
        DayLog.self,
        ActiveChallenge.self,
        BadgeUnlock.self,
    ])

    static func make(inMemory: Bool = false) throws -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: inMemory)
        return try ModelContainer(for: schema, configurations: configuration)
    }
}
