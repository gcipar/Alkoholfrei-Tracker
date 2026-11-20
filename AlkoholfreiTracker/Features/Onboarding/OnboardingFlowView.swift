import SwiftData
import SwiftUI

struct OnboardingFlowView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var model = OnboardingModel()
    @State private var saveError = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    stepContent
                    footer
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .background(Color(.systemBackground))
            .navigationTitle("Alkoholfrei-Tracker")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Speichern fehlgeschlagen", isPresented: $saveError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Die Angaben konnten nicht auf dem Gerät gespeichert werden.")
            }
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch model.step {
        case 0:
            GoalStepContent(model: model)
        case 1:
            StartDateStepContent(model: model)
        default:
            DrinksStepContent(model: model)
        }
    }

    private var footer: some View {
        VStack(spacing: 12) {
            if model.step > 0 {
                Button {
                    model.step -= 1
                } label: {
                    Text("Zurück")
                        .frame(maxWidth: .infinity)
                }
            }
            Button {
                advance()
            } label: {
                Text(model.step == 2 ? "Fertig" : "Weiter")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityHint(model.step == 2 ? "Speichert dein Ziel auf diesem Gerät" : "Nächster Schritt")
        }
        .padding(.top, 8)
    }

    private func advance() {
        if model.step < 2 {
            model.step += 1
            return
        }
        guard let window = model.resolvedWindow() else {
            saveError = true
            return
        }
        do {
            try TrackingStore.completeOnboarding(
                context: modelContext,
                goal: model.goalKind,
                startDate: model.startDate,
                window: window,
                drinks: model.drinks
            )
        } catch {
            saveError = true
        }
    }
}

struct GoalStepContent: View {
    @Bindable var model: OnboardingModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
                Text("Was möchtest du angehen?")
                    .font(.title2.weight(.semibold))
                    .accessibilityAddTraits(.isHeader)
                Text("Ein privates Tagebuch für alkoholfreie Tage. Keine medizinische Beratung.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                goalButton(.dryJanuary, title: "Dry January", detail: dryJanuaryDetail)
                goalButton(.lent, title: "Fastenzeit", detail: lentDetail)
                goalButton(.custom, title: "Eigenes Ziel", detail: "Eine feste Anzahl Tage")
                goalButton(.openEnded, title: "Ohne Enddatum", detail: "Tage zählen, ohne festes Ende")
                if model.goalKind == .custom {
                    Stepper(value: $model.customLength, in: 1...366) {
                        Text("Anzahl Tage: \(model.customLength)")
                    }
                    .accessibilityValue("\(model.customLength) Tage")
                }
        }
    }

    private var dryJanuaryDetail: String {
        guard let window = preview(for: .dryJanuary), let year = window.year else {
            return "1. bis 31. Januar"
        }
        return "1. bis 31. Januar \(year)"
    }

    private var lentDetail: String {
        guard let window = preview(for: .lent), let end = window.endDate else {
            return "Aschermittwoch bis Karsamstag"
        }
        return "\(window.startDate.formatted(date: .abbreviated, time: .omitted)) – \(end.formatted(date: .abbreviated, time: .omitted))"
    }

    private func preview(for kind: GoalKind) -> ChallengeWindow? {
        ChallengePlanner.window(kind: kind, today: .now, customStart: model.startDate, customLength: model.customLength)
    }

    private func goalButton(_ kind: GoalKind, title: String, detail: String) -> some View {
        let selected = model.goalKind == kind
        return Button {
            model.select(kind)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text(detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selected ? Color.accentColor : Color.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

struct StartDateStepContent: View {
    @Bindable var model: OnboardingModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
                Text("Wann beginnt dein Zähler?")
                    .font(.title2.weight(.semibold))
                    .accessibilityAddTraits(.isHeader)
                Text("Du trägst jeden Tag selbst ein. Tage ohne Eintrag zählen nicht mit.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                DatePicker(
                    "Startdatum",
                    selection: Binding(
                        get: { model.startDate },
                        set: { model.updateStartDate($0) }
                    ),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .accessibilityLabel("Startdatum")
        }
    }
}

struct DrinksStepContent: View {
    @Bindable var model: OnboardingModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
                Text("Dein übliches Trinken")
                    .font(.title2.weight(.semibold))
                    .accessibilityAddTraits(.isHeader)
                Text("Daraus entsteht nur eine Schätzung für Geld und Kalorien. Die Zahlen sind Startwerte, keine Nährwertberatung.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                ForEach($model.drinks) { $drink in
                    DrinkEditorRow(drink: $drink)
                }
                Button("Getränk hinzufügen") {
                    model.addDrink()
                }
                .accessibilityHint("Fügt eine leere Zeile hinzu")
                if model.drinks.count > 1 {
                    Button("Letztes Getränk entfernen", role: .destructive) {
                        guard !model.drinks.isEmpty else { return }
                        model.drinks.removeLast()
                    }
                }
        }
    }
}

private struct DrinkEditorRow: View {
    @Binding var drink: DraftDrink

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Name", text: $drink.name)
                .textInputAutocapitalization(.sentences)
                .accessibilityLabel("Name des Getränks")
            HStack {
                labeledField("Pro Woche", text: $drink.weeklyCountText)
                labeledField("Preis in Euro", text: $drink.priceText)
                labeledField("kcal", text: $drink.kcalText)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private func labeledField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField(title, text: text)
                .keyboardType(.decimalPad)
                .accessibilityLabel(title)
        }
    }
}
