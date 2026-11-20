import SwiftUI

struct SettingsView: View {
    @AppStorage(ProAccess.debugKey) private var debugPro = false

    var body: some View {
        NavigationStack {
            List {
                #if DEBUG
                Section {
                    Toggle("Pro testen", isOn: $debugPro)
                } footer: {
                    Text("Nur in der Debug-Version. Der echte Kauf folgt später.")
                }
                #endif
                Section {
                    Text("Getränke, Erinnerung und Zurücksetzen folgen.")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Einstellungen")
        }
    }
}
