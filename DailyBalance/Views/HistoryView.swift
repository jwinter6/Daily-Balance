import SwiftUI
import Charts

enum HistoryRange: String, CaseIterable, Identifiable {
    case week = "7 Tage", month = "30 Tage", quarter = "90 Tage", year = "1 Jahr", all = "Gesamt"
    var id: String { rawValue }
    var days: Int? {
        switch self { case .week: 7; case .month: 30; case .quarter: 90; case .year: 365; case .all: nil }
    }
}

struct HistoryView: View {
    @Environment(AppStore.self) private var store
    @State private var range = HistoryRange.month
    @State private var day = DayKey(Date())
    @State private var section = 0
    private var filteredMeasurements: [BodyMeasurements] {
        guard let count = range.days, let start = Calendar.current.date(byAdding: .day, value: -(count - 1), to: Date()) else { return store.bodyMeasurements }
        let first = DayKey(start)
        return store.bodyMeasurements.filter { $0.day >= first && $0.day <= DayKey(Date()) }
    }
    private var filteredDays: [DayKey] {
        Set(filtered.map(\.day)).union(filteredMeasurements.map(\.day)).sorted(by: >)
    }
    private var filtered: [DailyValue] {
        guard let count = range.days, let start = Calendar.current.date(byAdding: .day, value: -(count - 1), to: Date()) else { return store.entries }
        let first = DayKey(start)
        return store.entries.filter { $0.day >= first && $0.day <= DayKey(Date()) }
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 8) {
                    SectionEyebrow(title: "Schritt für Schritt")
                    Text("Deine Entwicklung.").font(.largeTitle.weight(.bold)).tracking(-1)
                    Text("Ein Blick auf das, was du festgehalten hast.").font(.subheadline).foregroundStyle(.secondary)
                }
                Picker("Bereich", selection: $section) {
                    Text("Übersicht").tag(0)
                    Text("Körpermaße").tag(1)
                }.pickerStyle(.segmented).accessibilityIdentifier("historySection")
                Picker("Zeitraum", selection: $range) {
                    ForEach(HistoryRange.allCases) { range in Text(range.rawValue).tag(range) }
                }.pickerStyle(.segmented)
                if section == 0 {
                    TrendCard(title: "Gewicht", symbol: "scalemass", points: Trends.points(filtered),
                              target: store.settings.targetWeight, metric: nil)
                    ForEach(Metric.allCases) { metric in
                        TrendCard(title: metric.title, symbol: metric.symbol,
                                  points: Trends.points(filtered, metric: metric), metric: metric)
                    }
                } else {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "ruler").font(.title2).foregroundStyle(Color.balanceTeal)
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Deine Körpermaße").font(.title2.weight(.semibold))
                            Text("Eine Messung pro Woche. Die Diagramme zeigen deine tatsächlichen Messtage. Links und rechts bleiben getrennt.")
                                .font(.subheadline).foregroundStyle(.secondary)
                        }
                    }.padding(.vertical, 4)
                    ForEach(BodyMeasurement.allCases) { measurement in
                        TrendCard(title: measurement.title, symbol: "ruler",
                                  points: Trends.points(filteredMeasurements, measurement: measurement), metric: nil,
                                  unit: "cm", seriesID: "body." + measurement.rawValue,
                                  seriesColor: measurement == .rightThigh ? .balanceBlue : .balanceTeal)
                    }
                }
                BalanceCard {
                    Label("Dein Kalender", systemImage: "calendar").font(.headline)
                    MonthCalendar(selected: $day, documented: store.documentedDays, mealDays: Set(store.meals.map(\.day)))
                    NavigationLink { DayDashboard(day: day) } label: {
                        Label("\(day.date().formatted(.dateTime.day().month())) öffnen", systemImage: "arrow.up.right")
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }.buttonStyle(.borderedProminent).tint(.balanceTeal)
                }
                NavigationLink {
                    List(filteredDays) { day in
                        NavigationLink { DayDashboard(day: day) } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(day.date(), format: .dateTime.weekday().day().month().year())
                                if let entry = store.entry(for: day) {
                                    if let weight = entry.weight {
                                        Text("\(weight.formatted(.number.precision(.fractionLength(1)))) kg").foregroundStyle(.secondary)
                                    }
                                    Text(Metric.allCases.compactMap { metric in
                                        entry[metric].map { "\(metric.title): \(metric.label($0))" }
                                    }.joined(separator: " · ")).font(.caption).foregroundStyle(.secondary)
                                }
                                if let measurements = store.measurements(for: day) {
                                    Text(BodyMeasurement.allCases.compactMap { measurement in
                                        measurements[measurement].map { "\(measurement.shortTitle): \($0.formatted(.number.precision(.fractionLength(1)))) cm" }
                                    }.joined(separator: " · ")).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }.accessibilityIdentifier("historyDay." + day.rawValue)
                    }.navigationTitle("Gespeicherte Werte")
                } label: {
                    Label("Alle Messwerte im Zeitraum", systemImage: "list.bullet").frame(maxWidth: .infinity, minHeight: 44)
                }.buttonStyle(.bordered).accessibilityIdentifier("allHistoryValues")
                Text("Bewertungen sind subjektiv. Die App dokumentiert deine Angaben und gibt keine medizinischen Empfehlungen.")
                    .font(.caption).foregroundStyle(.secondary)
            }.padding(20)
        }.journalBackground().navigationTitle("Verlauf").navigationBarTitleDisplayMode(.inline)
    }
}

struct TrendCard: View {
    let title: String
    let symbol: String
    let points: [ChartPoint]
    var target: Double? = nil
    let metric: Metric?
    var unit = "kg"
    var seriesID: String? = nil
    var seriesColor: Color? = nil
    private var identifier: String { seriesID ?? metric?.rawValue ?? "weight" }
    @State private var selectedDate: Date?
    private var tint: Color { seriesColor ?? (metric == .cravings ? .balanceBlue : .balanceTeal) }
    private var selected: ChartPoint? {
        guard let selectedDate else { return nil }
        return points.min { abs($0.date.timeIntervalSince(selectedDate)) < abs($1.date.timeIntervalSince(selectedDate)) }
    }
    private var domain: ClosedRange<Double> {
        if metric != nil { return 0.5...5.5 }
        let values = points.map(\.value) + (target.map { [$0] } ?? [])
        return ((values.min() ?? 0) - 1)...((values.max() ?? 1) + 1)
    }
    private var dateDomain: ClosedRange<Date> {
        let first = points.first?.date ?? Date()
        let last = points.last?.date ?? first
        guard first == last else { return first...last }
        let calendar = Calendar.current
        let before = calendar.date(byAdding: .day, value: -1, to: first) ?? first.addingTimeInterval(-86_400)
        let after = calendar.date(byAdding: .day, value: 1, to: first) ?? first.addingTimeInterval(86_400)
        return before...after
    }
    var body: some View {
        BalanceCard {
            Label(title, systemImage: symbol).font(.headline)
            if points.isEmpty {
                Text("Hier wächst dein Verlauf mit deinen Einträgen.").font(.subheadline).foregroundStyle(.secondary).padding(.vertical, 20)
            } else {
                if metric == nil { weightSummary }
                else {
                    let average = points.map(\.value).reduce(0, +) / Double(points.count)
                    HStack(alignment: .firstTextBaseline) {
                        Text(average, format: .number.precision(.fractionLength(1))).font(.title.weight(.semibold))
                        Text("/ 5 im Durchschnitt").font(.caption).foregroundStyle(.secondary)
                    }
                }
                Chart {
                    ForEach(points) { point in
                        LineMark(x: .value("Datum", point.date), y: .value(title, point.value))
                            .interpolationMethod(.linear).foregroundStyle(tint)
                        PointMark(x: .value("Datum", point.date), y: .value(title, point.value))
                            .foregroundStyle(tint).symbolSize(points.count > 100 ? 9 : 24)
                            .accessibilityLabel(point.day.date().formatted(date: .abbreviated, time: .omitted))
                            .accessibilityValue(valueLabel(point.value))
                    }
                    if metric == nil, let target {
                        RuleMark(y: .value("Zielgewicht", target)).lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                            .foregroundStyle(.secondary).annotation(position: .top, alignment: .leading) {
                                Text("Ziel \(target.formatted()) \(unit)").font(.caption2).foregroundStyle(.secondary)
                            }
                    }
                    if let selected {
                        RuleMark(x: .value("Ausgewählt", selected.date)).foregroundStyle(tint.opacity(0.35))
                    }
                }
                .chartXScale(domain: dateDomain)
                .chartYScale(domain: domain)
                .chartXAxis { AxisMarks(values: points.count == 1 ? .stride(by: .day) : .automatic(desiredCount: 4)) { _ in AxisGridLine(); AxisValueLabel(format: .dateTime.day().month()) } }
                .chartYAxis { AxisMarks(values: metric == nil ? .automatic(desiredCount: 4) : .stride(by: 1)) }
                .chartXSelection(value: $selectedDate)
                .chartGesture { proxy in
                    SpatialTapGesture().onEnded { event in
                        proxy.selectXValue(at: event.location.x)
                    }
                }
                .frame(height: 180)
                .accessibilityIdentifier("trendChart.\(identifier)")
                if let selected {
                    Text("\(selected.day.date().formatted(.dateTime.day().month().year())) · \(valueLabel(selected.value))")
                        .font(.caption.weight(.medium)).foregroundStyle(tint)
                        .accessibilityIdentifier("trendSelection.\(identifier)")
                } else {
                    Text("\(points.count == 1 ? "1 Messwert" : "\(points.count) Messwerte") · Tippe auf das Diagramm für Details.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }
    private func valueLabel(_ number: Double) -> String {
        if let metric { return "\(metric.label(Int(number))) (\(Int(number))/5)" }
        return number.formatted(.number.precision(.fractionLength(1))) + " " + unit
    }
    private var weightSummary: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 20) { stats }
            VStack(alignment: .leading, spacing: 12) { stats }
        }
    }
    @ViewBuilder private var stats: some View {
        if let first = points.first, let last = points.last {
            statistic("Start", first.value)
            statistic("Zuletzt", last.value)
            statistic("Veränderung", last.value - first.value)
        }
    }
    private func statistic(_ label: String, _ value: Double) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text("\(value.formatted(.number.precision(.fractionLength(1)))) \(unit)").font(.subheadline.weight(.semibold)).monospacedDigit()
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}
