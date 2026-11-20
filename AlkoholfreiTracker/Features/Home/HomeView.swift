import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var logs: [DayLog]
    @Query private var drinks: [DrinkTemplate]
    @Query private var challenges: [ActiveChallenge]
    @Query private var settings: [UserSettings]
    @State private var saveError = false

    @ScaledMetric(relativeTo: .largeTitle) private var counterSize: CGFloat = 72

    private var summary: HomeSummary {
        let logged = logs.map { LoggedDay(day: $0.day, status: $0.status) }
        let estimates = drinks.map {
            DrinkEstimate(weeklyCount: $0.weeklyCount, priceEUR: $0.priceEUR, kcalPerUnit: $0.kcalPerUnit)
        }
        return HomeSummaryBuilder.make(
            logs: logged,
            drinks: estimates,
            window: challenges.first?.window,
            trackingStart: settings.first?.trackingStartDate ?? .now,
            today: .now
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    counter
                    if let progress = summary.progress {
                        ChallengeCard(progress: progress)
                    }
                    savings
                    checkIn
                }
                .padding(20)
            }
            .navigationTitle("Heute")
            .alert("Speichern fehlgeschlagen", isPresented: $saveError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Der Eintrag konnte nicht gespeichert werden.")
            }
        }
    }

    private var counter: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(summary.alcoholFreeDays, format: .number)
                .font(.system(size: counterSize, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.4)
                .lineLimit(1)
                .accessibilityLabel("\(summary.alcoholFreeDays) alkoholfreie Tage")
            Text("Alkoholfreie Tage")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("Serie: \(summary.streakDays)")
                .font(.title3.weight(.semibold))
                .accessibilityLabel("Serie, \(summary.streakDays) Tage")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var savings: some View {
        HStack(spacing: 12) {
            savingsCard(
                title: "Geschätzt gespart",
                value: summary.moneySavedEUR.formatted(.currency(code: "EUR")),
                caption: "geschätzt"
            )
            savingsCard(
                title: "Geschätzte Kalorien",
                value: summary.kcalSaved.formatted(.number.precision(.fractionLength(0))),
                caption: "kcal, geschätzt"
            )
        }
    }

    private func savingsCard(title: String, value: String, caption: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.semibold))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(caption)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }

    private var checkIn: some View {
        VStack(alignment: .leading, spacing: 12) {
            if summary.trackingStartsInFuture {
                Text("Dein Start ist am \(summary.trackingStartDate.formatted(date: .abbreviated, time: .omitted)).")
                    .font(.body)
                    .foregroundStyle(.secondary)
            } else {
                Button {
                    save(.alcoholFree)
                } label: {
                    Text("Heute alkoholfrei")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityHint("Zählt den heutigen Tag als alkoholfrei")

                Button {
                    save(.drank)
                } label: {
                    Text("Heute getrunken")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .accessibilityHint("Setzt die Serie zurück. Die alkoholfreien Tage bleiben gezählt.")
            }

            if summary.todayStatus == .drank {
                Text("Alles gut. Deine alkoholfreien Tage bleiben gezählt. Die Serie beginnt beim nächsten alkoholfreien Tag von vorn.")
                    .font(.body)
                    .foregroundStyle(.primary)
                    .accessibilityLabel("Alles gut. Deine alkoholfreien Tage bleiben gezählt. Die Serie beginnt beim nächsten alkoholfreien Tag von vorn.")
            } else if summary.todayStatus == .alcoholFree {
                Text("Heute ist als alkoholfrei gespeichert. Du kannst den Eintrag noch ändern.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func save(_ status: DayStatus) {
        do {
            try TrackingStore.setToday(status: status, context: modelContext)
        } catch {
            saveError = true
        }
    }
}

private struct ChallengeCard: View {
    var progress: ChallengeProgress

    @ScaledMetric(relativeTo: .body) private var ringSize: CGFloat = 72

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            ProgressRing(fraction: progress.fraction)
                .frame(width: ringSize, height: ringSize)
                .accessibilityLabel(progress.title)
                .accessibilityValue(detail)
            VStack(alignment: .leading, spacing: 4) {
                Text(progress.title)
                    .font(.headline)
                Text(headline)
                    .font(.subheadline)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }

    private var headline: String {
        switch progress.phase {
        case .upcoming(let start):
            "Beginnt am \(start.formatted(date: .abbreviated, time: .omitted))"
        case .active(let dayIndex, let length, _):
            "Tag \(dayIndex) von \(length)"
        case .finished:
            "Abgeschlossen"
        case .openEnded(_, let next):
            if let next {
                "Nächste Marke: \(next) Tage"
            } else {
                "100 Tage erreicht"
            }
        }
    }

    private var detail: String {
        switch progress.phase {
        case .upcoming:
            "Noch nicht gestartet"
        case .active(_, _, let freeDays):
            "\(freeDays) alkoholfreie Tage in dieser Zeit"
        case .finished(let freeDays, let length):
            "\(freeDays) von \(length) Tagen alkoholfrei"
        case .openEnded(let freeDays, _):
            "\(freeDays) alkoholfreie Tage"
        }
    }
}

private struct ProgressRing: View {
    var fraction: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.accentColor.opacity(0.2), lineWidth: 8)
            Circle()
                .trim(from: 0, to: min(max(fraction, 0), 1))
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .accessibilityHidden(true)
    }
}
