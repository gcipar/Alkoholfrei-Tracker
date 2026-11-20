import SwiftData
import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Heute", systemImage: "sun.max")
                }
            PlaceholderTab(title: "Fortschritt", systemImage: "leaf")
                .tabItem {
                    Label("Fortschritt", systemImage: "leaf")
                }
            PlaceholderTab(title: "Statistik", systemImage: "calendar")
                .tabItem {
                    Label("Statistik", systemImage: "calendar")
                }
            PlaceholderTab(title: "Einstellungen", systemImage: "gearshape")
                .tabItem {
                    Label("Einstellungen", systemImage: "gearshape")
                }
        }
    }
}

struct PlaceholderTab: View {
    var title: String
    var systemImage: String

    var body: some View {
        NavigationStack {
            ContentUnavailableView(title, systemImage: systemImage, description: Text("Dieser Bereich folgt."))
                .navigationTitle(title)
        }
    }
}

struct RootView: View {
    @Query private var settings: [UserSettings]

    var body: some View {
        if settings.contains(where: \.onboardingCompleted) {
            MainTabView()
        } else {
            OnboardingFlowView()
        }
    }
}
