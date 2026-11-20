import SwiftData
import SwiftUI

@main
struct AlkoholfreiTrackerApp: App {
    private let container: ModelContainer?

    init() {
        container = try? AppModelContainer.make()
    }

    var body: some Scene {
        WindowGroup {
            if let container {
                PlaceholderHomeView()
                    .modelContainer(container)
            } else {
                ContentUnavailableView(
                    "Daten konnten nicht geöffnet werden",
                    systemImage: "externaldrive.badge.xmark"
                )
            }
        }
    }
}
