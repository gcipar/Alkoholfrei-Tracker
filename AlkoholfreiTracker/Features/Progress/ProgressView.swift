import SwiftData
import SwiftUI

struct ProgressScreen: View {
    @Query private var logs: [DayLog]
    @Query(sort: \BadgeUnlock.dayCount) private var badges: [BadgeUnlock]

    private var total: Int {
        StreakCalculator.alcoholFreeCount(logs.map { LoggedDay(day: $0.day, status: $0.status) })
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    GardenView(stage: MilestoneCatalog.stage(for: total))
                    Text("\(total) alkoholfreie Tage lassen die Pflanze wachsen.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                    Text("Marken")
                        .font(.title3.weight(.semibold))
                        .accessibilityAddTraits(.isHeader)
                    BadgeGrid(total: total, unlocked: Set(badges.map(\.dayCount)))
                }
                .padding(20)
            }
            .background(Color(.systemBackground))
            .navigationTitle("Fortschritt")
        }
    }
}

struct GardenView: View {
    var stage: GardenStage

    @ScaledMetric(relativeTo: .largeTitle) private var plot: CGFloat = 240

    var body: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color(.secondarySystemBackground))
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.accentColor.opacity(0.22))
                .frame(height: plot * 0.22)
                .padding(.horizontal, 28)
                .padding(.bottom, 20)
            plant
                .padding(.bottom, plot * 0.18)
        }
        .frame(maxWidth: .infinity)
        .frame(height: plot)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(stage.spokenName)
    }

    private var plant: some View {
        VStack(spacing: 0) {
            symbol
            if stemHeight > 0 {
                Capsule()
                    .fill(Color.accentColor)
                    .frame(width: max(4, plot * 0.02), height: stemHeight)
            }
        }
    }

    @ViewBuilder
    private var symbol: some View {
        switch stage {
        case .seed:
            Circle()
                .fill(Color.accentColor)
                .frame(width: plot * 0.08, height: plot * 0.08)
        default:
            Image(systemName: stage.symbolName)
                .font(.system(size: plot * stage.symbolScale))
                .foregroundStyle(Color.accentColor)
        }
    }

    private var stemHeight: CGFloat {
        switch stage {
        case .seed: 0
        case .sprout: plot * 0.08
        case .youngPlant: plot * 0.14
        case .plant: plot * 0.2
        case .bush: plot * 0.16
        case .tree: plot * 0.28
        }
    }
}

private extension GardenStage {
    var symbolName: String {
        switch self {
        case .seed: "circle.fill"
        case .sprout: "leaf"
        case .youngPlant: "leaf.fill"
        case .plant: "camera.macro"
        case .bush: "tree"
        case .tree: "tree.fill"
        }
    }

    var symbolScale: CGFloat {
        switch self {
        case .seed: 0.08
        case .sprout: 0.16
        case .youngPlant: 0.22
        case .plant: 0.26
        case .bush: 0.3
        case .tree: 0.36
        }
    }

    var spokenName: String {
        switch self {
        case .seed: "Pflanze: Samen"
        case .sprout: "Pflanze: Keimling"
        case .youngPlant: "Pflanze: junger Trieb"
        case .plant: "Pflanze: gewachsen"
        case .bush: "Pflanze: Busch"
        case .tree: "Pflanze: Baum"
        }
    }
}

struct BadgeGrid: View {
    var total: Int
    var unlocked: Set<Int>

    private let columns = [GridItem(.adaptive(minimum: 96), spacing: 12)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(MilestoneCatalog.thresholds, id: \.self) { days in
                BadgeTile(days: days, isUnlocked: unlocked.contains(days) || total >= days)
            }
        }
    }
}

private struct BadgeTile: View {
    var days: Int
    var isUnlocked: Bool

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: isUnlocked ? "seal.fill" : "seal")
                .font(.title2)
                .foregroundStyle(isUnlocked ? Color.accentColor : Color.secondary)
            Text("\(days)")
                .font(.headline)
            Text(title)
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 110)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
        .opacity(isUnlocked ? 1 : 0.55)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(days) Tage")
        .accessibilityValue(isUnlocked ? "Erreicht" : "Noch nicht erreicht")
    }

    private var title: String {
        switch days {
        case 1: "Erster Tag"
        case 7: "Eine Woche"
        case 14: "Zwei Wochen"
        case 31: "Ein Monat"
        case 40: "Fastenzeit"
        case 100: "Hundert Tage"
        default: "\(days) Tage"
        }
    }
}
