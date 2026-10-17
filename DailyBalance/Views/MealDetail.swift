import SwiftUI

struct MealDetail: View {
    let meal: MealValue
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var editor: MealEditorRoute?
    @State private var confirmDelete = false
    @State private var deleting = false
    private var current: MealValue { store.meals.first { $0.id == meal.id } ?? meal }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    LocalPhoto(name: current.imageName, thumbnail: false, service: store.images)
                        .frame(height: 360).clipShape(RoundedRectangle(cornerRadius: 24))
                    Text(current.category.rawValue).font(.largeTitle.weight(.bold))
                    Text(current.day.date().formatted(.dateTime.weekday(.wide).day().month(.wide).year()))
                        .foregroundStyle(.secondary)
                    Label(timeText, systemImage: "clock").foregroundStyle(.secondary)
                    if !current.notes.isEmpty { Text(current.notes).font(.body) }
                    if store.canEdit(current.day) {
                    Button("Mahlzeit bearbeiten", systemImage: "square.and.pencil") {
                        editor = MealEditorRoute(meal: current)
                    }.buttonStyle(.borderedProminent).tint(.balanceTeal)
                    Button("Mahlzeit löschen", role: .destructive) { confirmDelete = true }.padding(.top, 12)
                    } else {
                        Label("Vergangene Tage können nur angesehen werden.", systemImage: "lock.fill")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }.padding(20)
            }
            .journalBackground().navigationTitle("Mahlzeit").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Fertig") { dismiss() } } }
            .disabled(deleting)
            .confirmationDialog("Mahlzeit und Foto endgültig löschen?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Löschen", role: .destructive) {
                    Task {
                        deleting = true
                        do { try await store.deleteMeal(current); dismiss() }
                        catch { store.errorMessage = error.localizedDescription }
                        deleting = false
                    }
                }
            }
        }
        .sheet(item: $editor) { route in MealEditor(route: route).protectJournal() }
    }
    private var timeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = TimeZone(identifier: current.timeZoneID) ?? .current
        return "\(formatter.string(from: current.timestamp)) Uhr · \(current.timeZoneID)"
    }
}
