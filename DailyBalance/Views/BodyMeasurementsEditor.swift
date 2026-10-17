import SwiftUI

struct BodyMeasurementsEditor: View {
    let day: DayKey
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var draft: BodyMeasurements?
    @State private var inputs: [BodyMeasurement: String] = [:]
    @State private var error: String?
    @State private var confirmDelete = false

    private var weekInterval: DateInterval { WeekKey.interval(containing: day) }
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Deine Körpermaße", systemImage: "ruler").font(.title2.weight(.semibold))
                        Text("Woche vom \(weekInterval.start.formatted(.dateTime.day().month())) bis \(weekInterval.end.addingTimeInterval(-1).formatted(.dateTime.day().month().year()))")
                            .font(.subheadline).foregroundStyle(.secondary)
                        Text("Ein Eintrag pro Kalenderwoche, Montag bis Sonntag.").font(.caption).foregroundStyle(.secondary)
                    }.padding(.vertical, 6)
                }
                Section {
                    LabeledContent("Messtag", value: (draft?.day ?? day).date().formatted(date: .abbreviated, time: .omitted))
                }
                Section {
                    ForEach(BodyMeasurement.allCases) { measurement in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(measurement.title).font(.subheadline.weight(.medium))
                            HStack(alignment: .firstTextBaseline) {
                                TextField("Optional", text: inputBinding(measurement))
                                    .keyboardType(.decimalPad).font(.title3.monospacedDigit())
                                    .accessibilityLabel(measurement.title + " in Zentimetern")
                                    .accessibilityIdentifier("bodyInput.\(measurement.rawValue)")
                                Text("cm").font(.subheadline).foregroundStyle(.secondary)
                            }
                        }.padding(.vertical, 4)
                    }
                } header: { Text("Umfänge · Zentimeter") } footer: {
                    Text("Alle Angaben sind freiwillig. Ein leeres Feld entfernt den jeweiligen Wert. Für vergleichbare Messungen immer dieselbe Stelle verwenden.")
                }
                if let error { Section { Text(error).foregroundStyle(.red) } }
                if store.weeklyMeasurements(for: day) != nil {
                    Section {
                        Button("Wochenmessung löschen", role: .destructive) { confirmDelete = true }
                            .accessibilityIdentifier("deleteBodyMeasurements")
                        Text("Gewicht, Bewertungen, Notizen und Mahlzeiten bleiben erhalten.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .disabled(!store.canEditMeasurements(for: day))
            .navigationTitle("Körpermaße").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") { save() }.fontWeight(.semibold)
                        .accessibilityIdentifier("saveBodyMeasurements").disabled(!store.canEditMeasurements(for: day))
                }
            }
            .confirmationDialog("Körpermaße dieser Woche endgültig löschen?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Körpermaße löschen", role: .destructive) {
                    do { try store.saveMeasurements(BodyMeasurements(day: draft?.day ?? day)); dismiss() }
                    catch { self.error = error.localizedDescription }
                }
            }
        }
        .onAppear {
            guard draft == nil else { return }
            let value = store.weeklyMeasurements(for: day) ?? BodyMeasurements(day: day)
            draft = value
            for measurement in BodyMeasurement.allCases {
                inputs[measurement] = value[measurement].map { String($0).replacingOccurrences(of: ".", with: ",") } ?? ""
            }
        }
    }
    private func inputBinding(_ measurement: BodyMeasurement) -> Binding<String> {
        Binding(get: { inputs[measurement] ?? "" }, set: { inputs[measurement] = $0 })
    }
    private func save() {
        guard var value = draft else { return }
        do {
            for measurement in BodyMeasurement.allCases {
                value[measurement] = try MeasurementInput.parse(inputs[measurement] ?? "")
            }
            try store.saveMeasurements(value)
            dismiss()
        } catch { self.error = error.localizedDescription }
    }
}
