import SwiftUI

struct MealsView: View {
    @Environment(AppStore.self) private var store
    @State private var day = DayKey(Date())
    @State private var mode = 0
    @State private var route: MealEditorRoute?
    @State private var detail: MealValue?
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 8) {
                    SectionEyebrow(title: "Dein visuelles Tagebuch")
                    Text("Essen festhalten.").font(.largeTitle.weight(.bold)).tracking(-1)
                    Text("Erinnerungen an deine Mahlzeiten. Ganz ohne Zählen.").font(.subheadline).foregroundStyle(.secondary)
                }
                BalanceCard {
                    MonthCalendar(selected: $day, documented: store.documentedDays, mealDays: Set(store.meals.map(\.day)))
                }
                Picker("Ansicht", selection: $mode) { Text("Tag").tag(0); Text("Woche").tag(1) }.pickerStyle(.segmented)
                if mode == 0 { daySection(day) }
                else {
                    ForEach(weekDays, id: \.self) { day in daySection(day) }
                }
                if store.canEdit(day) {
                Menu {
                    Button("Foto aufnehmen", systemImage: "camera") { route = .new(day: day, source: .camera) }
                    Button("Foto auswählen", systemImage: "photo") { route = .new(day: day, source: .library) }
                } label: {
                    Label("Mahlzeit hinzufügen", systemImage: "plus").frame(maxWidth: .infinity, minHeight: 44)
                }.buttonStyle(.borderedProminent).tint(.balanceTeal)
                }
                NavigationLink { DayDashboard(day: day) } label: {
                    Label("Alle Tageswerte ansehen", systemImage: "list.bullet.clipboard").frame(maxWidth: .infinity, minHeight: 44)
                }.buttonStyle(.bordered)
            }.padding(20)
        }
        .journalBackground().navigationTitle("Essen").navigationBarTitleDisplayMode(.inline)
        .sheet(item: $route) { route in MealEditor(route: route).protectJournal() }
        .sheet(item: $detail) { meal in MealDetail(meal: meal).protectJournal() }
    }
    private var weekDays: [DayKey] {
        var calendar = Calendar(identifier: .gregorian); calendar.firstWeekday = 2
        let start = calendar.dateInterval(of: .weekOfYear, for: day.date())!.start
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }.map { DayKey($0) }
    }
    @ViewBuilder private func daySection(_ day: DayKey) -> some View {
        let meals = store.meals(for: day)
        VStack(alignment: .leading, spacing: 14) {
            Text(day.date().formatted(.dateTime.weekday(.wide).day().month())).font(.headline)
            if meals.isEmpty {
                if mode == 0 {
                    EmptyJournal(title: "Noch keine Mahlzeit", message: "Halte die nächste mit einem Foto fest.", symbol: "photo.on.rectangle.angled")
                } else { Text("Keine Fotos").font(.caption).foregroundStyle(.secondary) }
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 145), spacing: 14)], spacing: 18) {
                ForEach(meals) { meal in
                    Button { detail = meal } label: {
                        VStack(alignment: .leading, spacing: 9) {
                            LocalPhoto(name: meal.imageName, service: store.images)
                                .frame(height: 150).clipShape(RoundedRectangle(cornerRadius: 18))
                            Text(meal.category.rawValue).font(.subheadline.weight(.semibold))
                            Text(meal.localTimeLabel + " Uhr")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }.buttonStyle(.plain)
                }
            }
        }
    }
}
