import SwiftUI
import WidgetKit

struct WidgetEntry: TimelineEntry {
    var date: Date
}

struct WidgetPlaceholderProvider: TimelineProvider {
    func placeholder(in context: Context) -> WidgetEntry {
        WidgetEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> Void) {
        completion(WidgetEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetEntry>) -> Void) {
        let entry = WidgetEntry(date: Date())
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: entry.date) ?? entry.date
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct AlkoholfreiWidgetView: View {
    var body: some View {
        Text("Alkoholfrei")
            .containerBackground(for: .widget) {
                Color(.secondarySystemBackground)
            }
            .accessibilityLabel("Alkoholfrei")
    }
}

struct AlkoholfreiWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "AlkoholfreiWidget", provider: WidgetPlaceholderProvider()) { _ in
            AlkoholfreiWidgetView()
        }
        .configurationDisplayName("Alkoholfrei")
        .description("Tage ohne Alkohol")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct AlkoholfreiWidgetBundle: WidgetBundle {
    var body: some Widget {
        AlkoholfreiWidget()
    }
}
