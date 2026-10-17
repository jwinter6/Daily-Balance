import SwiftUI

struct BodyMeasurementsCard: View {
    let day: DayKey
    @Environment(AppStore.self) private var store
    @State private var editor: DayEditorRoute?
    private var latest: BodyMeasurements? {
        if let weekly = store.weeklyMeasurements(for: day), weekly.day <= day { return weekly }
        return store.bodyMeasurements.last { $0.day <= day }
    }
    var body: some View {
        BalanceCard {
            HStack {
                Label("Körpermaße · wöchentlich", systemImage: "ruler").font(.headline)
                Spacer()
                Text("cm").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            }
            Label(store.weeklyMeasurements(for: day) == nil ? "Für diese Woche noch offen" : "Für diese Woche erfasst",
                  systemImage: store.weeklyMeasurements(for: day) == nil ? "calendar" : "checkmark.circle.fill")
                .font(.caption.weight(.medium)).foregroundStyle(Color.balanceTeal)
            if let latest {
                Text("Gemessen am \(latest.day.date().formatted(.dateTime.day().month().year()))")
                    .font(.caption).foregroundStyle(.secondary)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 135), alignment: .leading)], alignment: .leading, spacing: 16) {
                    ForEach(BodyMeasurement.allCases) { measurement in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(measurement.shortTitle).font(.caption).foregroundStyle(.secondary)
                            if let number = latest[measurement] {
                                Text(number.formatted(.number.precision(.fractionLength(1))) + " cm")
                                    .font(.title3.weight(.semibold)).monospacedDigit()
                            } else { Text("Noch offen").font(.subheadline).foregroundStyle(.secondary) }
                        }.accessibilityElement(children: .combine)
                    }
                }
            } else {
                Text("Brust, Bauch, Po und beide Oberschenkel. Eine Messung pro Woche genügt.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            if store.canEditMeasurements(for: day) {
            Button {
                editor = DayEditorRoute(day: day)
            } label: {
                Label(store.weeklyMeasurements(for: day) == nil ? "Wochenmessung eintragen" : "Wochenmessung bearbeiten", systemImage: "square.and.pencil")
                    .frame(maxWidth: .infinity, minHeight: 44)
            }.buttonStyle(.bordered).tint(.balanceTeal).accessibilityIdentifier("bodyMeasurementsCard")
            } else if store.canEdit(day), store.weeklyMeasurements(for: day) != nil {
                Label("Diese Wochenmessung ist abgeschlossen.", systemImage: "lock.fill")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .sheet(item: $editor) { route in BodyMeasurementsEditor(day: route.day).protectJournal() }
    }
}
