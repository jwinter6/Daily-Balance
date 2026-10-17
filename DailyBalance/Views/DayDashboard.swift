import SwiftUI

struct DayEditorRoute: Identifiable {
    let day: DayKey
    var id: String { day.rawValue }
}

struct DayDashboard: View {
    let day: DayKey
    @Environment(AppStore.self) private var store
    @State private var editor: DayEditorRoute?
    @State private var mealRoute: MealEditorRoute?
    @State private var selectedMeal: MealValue?
    private var entry: DailyValue? { store.entry(for: day) }
    private var food: [MealValue] { store.meals(for: day) }
    private var isToday: Bool { store.canEdit(day) }
    private var latestWeight: DailyValue? { store.entries.last { $0.weight != nil && $0.day <= day } }
    private var greeting: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<11: "Guten Morgen."
        case 11..<18: "Ein Moment für dich."
        default: "Wie war dein Tag?"
        }
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 9) {
                    SectionEyebrow(title: day.date().formatted(.dateTime.weekday(.wide).day().month(.wide)))
                    Text(isToday ? greeting : "Dein Tagesrückblick.")
                        .font(.largeTitle.weight(.bold)).tracking(-1)
                    Label(store.documentedDays.contains(day) ? "Dein Tag ist festgehalten" : "Dein Check-in · in weniger als einer Minute",
                          systemImage: store.documentedDays.contains(day) ? "checkmark.circle.fill" : "leaf")
                        .font(.subheadline).foregroundStyle(Color.balanceTeal)
                }.padding(.top, 10)
                if !isToday {
                    Label("Vergangene Tage können nur angesehen werden.", systemImage: "lock.fill")
                        .font(.caption).foregroundStyle(.secondary).accessibilityIdentifier("dayReadOnly")
                }
                weightCard
                BodyMeasurementsCard(day: day)
                BalanceCard {
                    SectionEyebrow(title: "Wie geht es dir?")
                    ForEach(Metric.allCases) { metric in
                        RatingSelector(metric: metric, value: entry?[metric]) { rating in
                            var value = entry ?? DailyValue(day: day)
                            value[metric] = rating
                            do { try store.save(value) } catch { store.errorMessage = error.localizedDescription }
                        }.disabled(!isToday)
                        if metric != Metric.allCases.last { Divider().padding(.vertical, 3) }
                    }
                    if isToday {
                        Text("Ein Tippen speichert. Erneutes Tippen entfernt die Auswahl.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                BalanceCard {
                    HStack {
                        Label("Deine Mahlzeiten", systemImage: "fork.knife").font(.headline)
                        Spacer()
                        Text("\(food.count)").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                    }
                    if food.isEmpty {
                        Text("Ein Foto genügt. Ohne Kalorien, ohne Aufwand.")
                            .font(.subheadline).foregroundStyle(.secondary)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 12) {
                                ForEach(food) { meal in
                                    Button { selectedMeal = meal } label: {
                                        VStack(alignment: .leading, spacing: 7) {
                                            LocalPhoto(name: meal.imageName, service: store.images)
                                                .frame(width: 130, height: 100).clipShape(RoundedRectangle(cornerRadius: 16))
                                            Text(meal.category.rawValue).font(.caption.weight(.semibold))
                                        }
                                    }.buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    if isToday {
                    Menu {
                        Button("Foto aufnehmen", systemImage: "camera") { mealRoute = .new(day: day, source: .camera) }
                        Button("Foto auswählen", systemImage: "photo.on.rectangle") { mealRoute = .new(day: day, source: .library) }
                    } label: {
                        Label("Mahlzeit hinzufügen", systemImage: "plus.circle.fill").frame(maxWidth: .infinity, minHeight: 44)
                    }.buttonStyle(.borderedProminent).tint(.balanceTeal).accessibilityIdentifier("addMeal")
                    }
                }
                BalanceCard {
                    HStack {
                        Label("Tagesnotizen", systemImage: "text.alignleft").font(.headline)
                        Spacer()
                        if isToday { Button("Bearbeiten") { editor = DayEditorRoute(day: day) }.font(.subheadline) }
                    }
                    Text(entry?.notes.isEmpty == false ? entry!.notes : "Platz für Gedanken, Beobachtungen oder besondere Momente.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
            }.padding(.horizontal, 20)
        }
        .journalBackground()
        .navigationTitle(isToday ? "Heute" : day.date().formatted(.dateTime.day().month().year()))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isToday {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Tag bearbeiten", systemImage: "square.and.pencil") { editor = DayEditorRoute(day: day) }
                    .accessibilityIdentifier("editDay")
            }
            }
        }
        .sheet(item: $editor) { route in DailyEditor(day: route.day).protectJournal() }
        .sheet(item: $mealRoute) { route in MealEditor(route: route).protectJournal() }
        .sheet(item: $selectedMeal) { meal in MealDetail(meal: meal).protectJournal() }
    }
    private var weightCard: some View {
        Button { editor = DayEditorRoute(day: day) } label: {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Label(entry?.weight == nil ? "Zuletzt erfasst" : "Dein Gewicht", systemImage: "scalemass")
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    Image(systemName: isToday ? "arrow.up.right" : "lock.fill").font(.subheadline)
                }
                HStack(alignment: .firstTextBaseline, spacing: 7) {
                    if let weight = latestWeight?.weight {
                        Text(weight, format: .number.precision(.fractionLength(1))).font(.system(.largeTitle, design: .rounded).weight(.semibold))
                        Text("kg").font(.title3)
                    } else {
                        Text("Dein erster Eintrag").font(.title2.weight(.semibold))
                    }
                }
                if !isToday {
                    Text("Gespeicherter Tagesstand").font(.caption)
                } else if entry?.weight == nil, let latestWeight {
                    Text("\(latestWeight.day.date().formatted(.dateTime.day().month())) · Gewicht für diesen Tag eintragen")
                        .font(.caption)
                } else { Text(entry?.weight == nil ? "Gewicht eintragen" : "Tippen zum Bearbeiten").font(.caption) }
            }
            .foregroundStyle(.white).padding(24).frame(maxWidth: .infinity, alignment: .leading)
            .background(LinearGradient(colors: [.balanceTeal, Color(red: 0.12, green: 0.37, blue: 0.39)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 26))
        }.buttonStyle(.plain).disabled(!isToday).accessibilityIdentifier("weightCard")
    }
}
