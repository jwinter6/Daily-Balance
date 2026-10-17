import SwiftUI

struct DailyEditor: View {
    let day: DayKey
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var draft: DailyValue?
    @State private var weight = ""
    @State private var error: String?
    @State private var confirmDelete = false
    var body: some View {
        NavigationStack {
            Form {
                Section("Gewicht · kg") {
                    TextField("z. B. 94,6", text: $weight).keyboardType(.decimalPad)
                        .accessibilityIdentifier("weightInput")
                    Text("Ein leeres Feld entfernt den Gewichtswert.").font(.caption).foregroundStyle(.secondary)
                }
                if draft != nil {
                    ForEach(Metric.allCases) { metric in
                        Section {
                            RatingSelector(metric: metric, value: draft?[metric]) { value in draft?[metric] = value }
                        }
                    }
                    Section("Notizen · freiwillig") {
                        TextField("Was möchtest du festhalten?", text: Binding(get: { draft?.notes ?? "" }, set: { draft?.notes = $0 }), axis: .vertical)
                            .lineLimit(4...10).accessibilityIdentifier("notesInput")
                    }
                }
                if let error { Section { Text(error).foregroundStyle(.red) } }
                if store.entry(for: day) != nil {
                    Section {
                        Button("Tageswerte löschen", role: .destructive) { confirmDelete = true }
                        Text("Körpermaße und Mahlzeiten bleiben erhalten und können in ihren Bereichen gelöscht werden.").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .disabled(!store.canEdit(day))
            .navigationTitle(day.date().formatted(.dateTime.day().month(.wide)))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") { save() }.fontWeight(.semibold).accessibilityIdentifier("saveDay").disabled(!store.canEdit(day))
                }
            }
            .confirmationDialog("Alle Tageswerte und Notizen löschen?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Tageswerte löschen", role: .destructive) {
                    do { try store.save(DailyValue(day: day)); dismiss() }
                    catch { self.error = error.localizedDescription }
                }
            }
        }
        .onAppear {
            guard draft == nil else { return }
            let value = store.entry(for: day) ?? DailyValue(day: day)
            draft = value
            weight = value.weight.map { String($0).replacingOccurrences(of: ".", with: ",") } ?? ""
        }
    }
    private func save() {
        guard var value = draft else { return }
        do {
            value.weight = try WeightInput.parse(weight)
            try store.save(value)
            dismiss()
        } catch { self.error = error.localizedDescription }
    }
}
