import SwiftUI

struct MonthCalendar: View {
    @Binding var selected: DayKey
    let documented: Set<DayKey>
    let mealDays: Set<DayKey>
    @State private var month = Date()
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "de_DE"); calendar.firstWeekday = 2
        return calendar
    }
    private var monthStart: Date { calendar.dateInterval(of: .month, for: month)!.start }
    private var cells: [Date?] {
        let offset = (calendar.component(.weekday, from: monthStart) + 5) % 7
        let count = calendar.range(of: .day, in: .month, for: monthStart)!.count
        return Array(repeating: nil, count: offset) + (0..<count).map { calendar.date(byAdding: .day, value: $0, to: monthStart) }
    }
    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Button("Vorheriger Monat", systemImage: "chevron.left") { move(-1) }.labelStyle(.iconOnly).frame(width: 44, height: 44)
                Spacer()
                Text(month.formatted(.dateTime.month(.wide).year())).font(.headline)
                Spacer()
                Button("Nächster Monat", systemImage: "chevron.right") { move(1) }.labelStyle(.iconOnly).frame(width: 44, height: 44)
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 5) {
                ForEach(["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"], id: \.self) { day in
                    Text(day).font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity)
                }
                ForEach(Array(cells.enumerated()), id: \.offset) { _, date in
                    if let date {
                        let day = DayKey(date)
                        Button { selected = day } label: {
                            VStack(spacing: 4) {
                                Text("\(calendar.component(.day, from: date))").font(.subheadline.weight(day == selected ? .bold : .regular))
                                HStack(spacing: 3) {
                                    if documented.contains(day) { Image(systemName: "circle.fill").font(.system(size: 4)) }
                                    if mealDays.contains(day) { Image(systemName: "fork.knife").font(.system(size: 7)) }
                                }.frame(height: 8)
                            }
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .foregroundStyle(day == selected ? Color.white : Color.primary)
                            .background(day == selected ? Color.balanceTeal : documented.contains(day) ? Color.balanceTeal.opacity(0.10) : .clear,
                                        in: RoundedRectangle(cornerRadius: 12))
                        }.buttonStyle(.plain).disabled(date > Date())
                            .accessibilityLabel("\(date.formatted(date: .complete, time: .omitted)), \(documented.contains(day) ? "dokumentiert" : "kein Eintrag")\(mealDays.contains(day) ? ", mit Mahlzeiten" : "")")
                            .accessibilityAddTraits(day == selected ? [.isSelected] : [])
                    } else { Color.clear.frame(height: 44) }
                }
            }
            HStack(spacing: 14) {
                Label("Eintrag", systemImage: "circle.fill")
                Label("Mahlzeiten", systemImage: "fork.knife")
            }.font(.caption2).foregroundStyle(.secondary)
        }
        .onAppear { month = selected.date() }
    }
    private func move(_ count: Int) { month = calendar.date(byAdding: .month, value: count, to: month) ?? month }
}
