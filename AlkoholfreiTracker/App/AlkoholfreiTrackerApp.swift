import SwiftData
import SwiftUI

@main
struct AlkoholfreiTrackerApp: App {
    private let container = AppModelContainer.makePersistentOrMemory()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
