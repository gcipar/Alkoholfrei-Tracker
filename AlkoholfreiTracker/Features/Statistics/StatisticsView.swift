import SwiftData
import SwiftUI

struct StatisticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var logs: [DayLog]
    @Query private var drinks: [DrinkTemplate]
    @AppStorage(ProAccess.debugKey) private var debugPro = false
    @State private var month = CivilCalendar.berlin.startOfDay(for: .now)
    @State private var selectedDay: EditableDay?
    @State private var saveError = false

    private var calendar: Calendar { CivilCalendar.berlin }
    private var isPro: Bool {
        #if DEBUG
        debugPro
        #else
        false
        #endif
    }

    private var loggedDays: [LoggedDay] {
        logs.map { LoggedDay(day: $0.day, status: $0.status) }
    }

    private var estimates: [DrinkEstimate] {
        drinks.map { DrinkEstimate(weeklyCount: $0.weeklyCount, priceEUR: $0.priceEUR, kcalPerUnit: $0.kcalPerUnit) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    monthHeader
                    if let grid = MonthCalendarBuilder.grid(containing: month, logs: loggedDays, calendar: calendar) {
                        calendarGrid(grid)
                        monthTotals(grid)
                    }
                    if isPro {
                        breakdown
                    } else {
                        Text("Wochen- und Monatsauswertung ist Teil von Pro.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(20)
            }
            .background(Color(.systemBackground))
            .navigationTitle("Statistik")
            .sheet(item: $selectedDay) { day in
                DayEditSheet(
                    day: day.date,
                    status: status(on: day.date),
                    onSelect: { status in
                        save(status, on: day.date)
                        selectedDay = nil
                    }
                )
                .presentationDetents([.medium])
            }
            .alert("Speichern fehlgeschlagen", isPresented: $saveError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Der Eintrag konnte nicht gespeichert werden.")
            }
        }
    }

    private var monthHeader: some View {
        HStack {
            Button {
                shiftMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .frame(minWidth: 44, minHeight: 44)
            }
            .disabled(!isPro)
            .accessibilityLabel("Vorheriger Monat")

            Spacer()
            Text(month.formatted(.dateTime.month(.wide).year()))
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            Spacer()

            Button {
                shiftMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .frame(minWidth: 44, minHeight: 44)
            }
            .disabled(!isPro)
            .accessibilityLabel("Nächster Monat")
        }
    }

    private func calendarGrid(_ grid: MonthGrid) -> some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
        return VStack(spacing: 8) {
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(Array(grid.weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .accessibilityHidden(true)
                }
                ForEach(Array(grid.weeks.enumerated()), id: \.offset) { _, week in
                    ForEach(0..<week.count, id: \.self) { index in
                        dayCell(week[index])
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func dayCell(_ day: CalendarDay?) -> some View {
        if let day {
            let future = calendar.startOfDay(for: day.date) > calendar.startOfDay(for: .now)
            Button {
                selectedDay = EditableDay(date: day.date)
            } label: {
                Text(calendar.component(.day, from: day.date), format: .number)
                    .font(.body)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(fill(for: day.status), in: RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(day.status == .alcoholFree ? Color.white : Color.primary)
            }
            .buttonStyle(.plain)
            .disabled(future)
            .opacity(future ? 0.35 : 1)
            .accessibilityLabel(accessibilityLabel(for: day))
        } else {
            Color.clear
                .frame(minHeight: 44)
        }
    }

    private func monthTotals(_ grid: MonthGrid) -> some View {
        let money = SavingsCalculator.moneySaved(drinks: estimates, alcoholFreeDays: grid.alcoholFreeDays)
        let kcal = SavingsCalculator.kcalSaved(drinks: estimates, alcoholFreeDays: grid.alcoholFreeDays)
        return VStack(alignment: .leading, spacing: 6) {
            Text("\(grid.alcoholFreeDays) alkoholfreie Tage in diesem Monat")
                .font(.headline)
            Text("Geschätzt \(money.formatted(.currency(code: "EUR"))) und \(kcal.formatted(.number.precision(.fractionLength(0)))) kcal")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var breakdown: some View {
        let freeDates = loggedDays.filter { $0.status == .alcoholFree }.map(\.day)
        let weeks = SavingsCalculator.byWeek(alcoholFreeDays: freeDates, drinks: estimates, calendar: calendar)
        let months = SavingsCalculator.byMonth(alcoholFreeDays: freeDates, drinks: estimates, calendar: calendar)
        return VStack(alignment: .leading, spacing: 16) {
            Text("Nach Woche")
                .font(.title3.weight(.semibold))
            if weeks.isEmpty {
                Text("Noch keine Woche mit Einträgen.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(weeks, id: \.periodStart) { period in
                    periodRow(period, style: .week)
                }
            }
            Text("Nach Monat")
                .font(.title3.weight(.semibold))
            if months.isEmpty {
                Text("Noch kein Monat mit Einträgen.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(months, id: \.periodStart) { period in
                    periodRow(period, style: .month)
                }
            }
        }
    }

    private func periodRow(_ period: PeriodSavings, style: PeriodStyle) -> some View {
        let title = style == .week
            ? period.periodStart.formatted(.dateTime.day().month(.abbreviated))
            : period.periodStart.formatted(.dateTime.month(.wide).year())
        return HStack {
            Text(title)
            Spacer()
            Text("\(period.alcoholFreeDays)")
                .accessibilityLabel("\(period.alcoholFreeDays) alkoholfreie Tage")
            Text(period.moneyEUR.formatted(.currency(code: "EUR")))
                .foregroundStyle(.secondary)
        }
        .font(.subheadline)
    }

    private func fill(for status: DayStatus?) -> Color {
        switch status {
        case .alcoholFree: Color.accentColor
        case .drank: Color.secondary.opacity(0.35)
        case nil: Color(.tertiarySystemFill)
        }
    }

    private func accessibilityLabel(for day: CalendarDay) -> String {
        let date = day.date.formatted(date: .abbreviated, time: .omitted)
        switch day.status {
        case .alcoholFree: return "\(date), alkoholfrei"
        case .drank: return "\(date), getrunken"
        case nil: return "\(date), kein Eintrag"
        }
    }

    private func status(on date: Date) -> DayStatus? {
        loggedDays.first { calendar.isDate($0.day, inSameDayAs: date) }?.status
    }

    private func shiftMonth(by value: Int) {
        guard isPro, let shifted = MonthCalendarBuilder.shiftMonth(from: month, by: value, calendar: calendar) else { return }
        month = shifted
    }

    private func save(_ status: DayStatus, on date: Date) {
        do {
            try TrackingStore.setStatus(status, on: date, context: modelContext)
        } catch {
            saveError = true
        }
    }
}

private enum PeriodStyle {
    case week
    case month
}

struct EditableDay: Identifiable, Hashable {
    var date: Date
    var id: Date { date }
}

struct DayEditSheet: View {
    var day: Date
    var status: DayStatus?
    var onSelect: (DayStatus) -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text(day.formatted(date: .complete, time: .omitted))
                    .font(.title3.weight(.semibold))
                Button {
                    onSelect(.alcoholFree)
                } label: {
                    Text("Alkoholfrei")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityHint("Zählt diesen Tag als alkoholfrei")

                Button {
                    onSelect(.drank)
                } label: {
                    Text("Getrunken")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .accessibilityHint("Setzt die Serie zurück. Die alkoholfreien Tage bleiben gezählt.")

                if status == .drank {
                    Text("Alles gut. Deine alkoholfreien Tage bleiben gezählt. Die Serie beginnt beim nächsten alkoholfreien Tag von vorn.")
                        .font(.body)
                }
                Spacer()
            }
            .padding(20)
            .background(Color(.systemBackground))
            .navigationTitle("Tag")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
