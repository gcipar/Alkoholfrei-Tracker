import SwiftUI

struct PlaceholderHomeView: View {
    var body: some View {
        ContentUnavailableView(
            "Alkoholfrei-Tracker",
            systemImage: "leaf",
            description: Text("Dein Zähler wird hier stehen.")
        )
        .accessibilityLabel("Alkoholfrei-Tracker")
    }
}
