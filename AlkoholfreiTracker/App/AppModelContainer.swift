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

    static func makePersistentOrMemory() -> ModelContainer {
        if let persistent = try? make(inMemory: false) {
            return persistent
        }
        if let memory = try? make(inMemory: true) {
            return memory
        }
        do {
            return try make(inMemory: true)
        } catch {
            preconditionFailure("SwiftData store could not be created.")
        }
    }
}
