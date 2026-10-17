import Foundation

/// A civil date, intentionally independent of the UTC instant and later time-zone changes.
struct DayKey: Hashable, Codable, Comparable, Sendable, Identifiable {
    let rawValue: String
    var id: String { rawValue }
    init(_ date: Date, calendar: Calendar = .current) {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = calendar.timeZone
        let c = gregorian.dateComponents([.year, .month, .day], from: date)
        rawValue = String(format: "%04d-%02d-%02d", c.year!, c.month!, c.day!)
    }
    init(rawValue: String) { self.rawValue = rawValue }
    func date(calendar: Calendar = .current) -> Date {
        let parts = rawValue.split(separator: "-").compactMap { Int($0) }
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = calendar.timeZone
        guard parts.count == 3, let result = gregorian.date(from: DateComponents(
            year: parts[0], month: parts[1], day: parts[2], hour: 12
        )) else { return .distantPast }
        return result
    }
    static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

enum Metric: String, Codable, CaseIterable, Identifiable, Sendable {
    case mood, energy, sleep, hunger, cravings
    var id: String { rawValue }
    var title: String {
        switch self {
        case .mood: "Wohlbefinden"
        case .energy: "Energie"
        case .sleep: "Schlafqualität"
        case .hunger: "Hunger"
        case .cravings: "Cravings"
        }
    }
    var symbol: String {
        switch self {
        case .mood: "face.smiling"
        case .energy: "bolt.fill"
        case .sleep: "moon.stars.fill"
        case .hunger: "fork.knife"
        case .cravings: "sparkles"
        }
    }
    var explanation: String {
        switch self {
        case .mood: "Wie fühlst du dich heute?"
        case .energy: "Wie wach und energiegeladen fühlst du dich?"
        case .sleep: "Wie erholsam war deine letzte Nacht?"
        case .hunger: "Dein körperliches Hungergefühl."
        case .cravings: "Verlangen nach Essen, unabhängig von körperlichem Hunger."
        }
    }
    var labels: [String] {
        switch self {
        case .mood: ["Sehr schlecht", "Schlecht", "Neutral", "Gut", "Sehr gut"]
        case .energy: ["Sehr müde", "Eher müde", "Normal", "Fit", "Sehr energiegeladen"]
        case .sleep: ["Sehr schlecht", "Schlecht", "Mittelmäßig", "Gut", "Sehr gut"]
        case .hunger: ["Kaum Hunger", "Wenig Hunger", "Normaler Hunger", "Viel Hunger", "Sehr starker Hunger"]
        case .cravings: ["Keine", "Gering", "Mittel", "Stark", "Sehr stark"]
        }
    }
    func label(_ value: Int?) -> String {
        guard let value, (1...5).contains(value) else { return "Noch offen" }
        return labels[value - 1]
    }
}

struct DailyValue: Codable, Identifiable, Equatable, Sendable {
    var id = UUID()
    var day: DayKey
    var weight: Double?
    var mood: Int?
    var energy: Int?
    var sleep: Int?
    var hunger: Int?
    var cravings: Int?
    var notes = ""
    var createdAt = Date()
    var updatedAt = Date()
    var isDocumented: Bool {
        weight != nil || Metric.allCases.contains { self[$0] != nil } || !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    subscript(metric: Metric) -> Int? {
        get {
            switch metric {
            case .mood: mood
            case .energy: energy
            case .sleep: sleep
            case .hunger: hunger
            case .cravings: cravings
            }
        }
        set {
            switch metric {
            case .mood: mood = newValue
            case .energy: energy = newValue
            case .sleep: sleep = newValue
            case .hunger: hunger = newValue
            case .cravings: cravings = newValue
            }
        }
    }
    func validated() throws -> Self {
        if let weight, !weight.isFinite || !(1...700).contains(weight) { throw BalanceError.invalidWeight }
        for metric in Metric.allCases {
            if let value = self[metric], !(1...5).contains(value) { throw BalanceError.invalidRating }
        }
        return self
    }
}

/// ISO calendar weeks start on Monday. The week-year can differ from the calendar year.
struct WeekKey: Hashable, Codable, Comparable, Sendable, Identifiable {
    let rawValue: String
    var id: String { rawValue }
    init(_ day: DayKey, calendar inputCalendar: Calendar = .current) {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = inputCalendar.timeZone
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: day.date(calendar: calendar))
        rawValue = String(format: "%04d-W%02d", components.yearForWeekOfYear!, components.weekOfYear!)
    }
    static func interval(containing day: DayKey, calendar inputCalendar: Calendar = .current) -> DateInterval {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = inputCalendar.timeZone
        return calendar.dateInterval(of: .weekOfYear, for: day.date(calendar: calendar))!
    }
    static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

enum BodyMeasurement: String, CaseIterable, Codable, Identifiable, Sendable {
    case chest, abdomen, hips, leftThigh, rightThigh
    var id: String { rawValue }
    var title: String {
        switch self {
        case .chest: "Brustumfang"
        case .abdomen: "Bauchumfang"
        case .hips: "Po-Umfang"
        case .leftThigh: "Oberschenkel links"
        case .rightThigh: "Oberschenkel rechts"
        }
    }
    var shortTitle: String {
        switch self {
        case .chest: "Brust"
        case .abdomen: "Bauch"
        case .hips: "Po"
        case .leftThigh: "Oberschenkel links"
        case .rightThigh: "Oberschenkel rechts"
        }
    }
}

struct BodyMeasurements: Codable, Identifiable, Equatable, Sendable {
    var id = UUID()
    var day: DayKey
    var chest: Double?
    var abdomen: Double?
    var hips: Double?
    var leftThigh: Double?
    var rightThigh: Double?
    var createdAt = Date()
    var updatedAt = Date()
    var week: WeekKey { WeekKey(day) }
    var isDocumented: Bool { BodyMeasurement.allCases.contains { self[$0] != nil } }
    subscript(measurement: BodyMeasurement) -> Double? {
        get {
            switch measurement {
            case .chest: chest
            case .abdomen: abdomen
            case .hips: hips
            case .leftThigh: leftThigh
            case .rightThigh: rightThigh
            }
        }
        set {
            switch measurement {
            case .chest: chest = newValue
            case .abdomen: abdomen = newValue
            case .hips: hips = newValue
            case .leftThigh: leftThigh = newValue
            case .rightThigh: rightThigh = newValue
            }
        }
    }
    func validated() throws -> Self {
        for measurement in BodyMeasurement.allCases {
            if let value = self[measurement], !value.isFinite || !(0.1...500).contains(value) {
                throw BalanceError.invalidMeasurement
            }
        }
        return self
    }
}

enum MeasurementInput {
    static func parse(_ text: String) throws -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return nil }
        let normalized = trimmed.replacingOccurrences(of: ",", with: ".")
        guard normalized.range(of: #"^\d{1,3}(\.\d{1,3})?$"#, options: .regularExpression) != nil,
              let number = Double(normalized), number.isFinite, (0.1...500).contains(number)
        else { throw BalanceError.invalidMeasurement }
        return number
    }
}

enum MealCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case breakfast = "Frühstück", lunch = "Mittagessen", dinner = "Abendessen", snack = "Snack", other = "Sonstiges"
    var id: String { rawValue }
    static func suggested(at date: Date, calendar: Calendar = .current) -> Self {
        switch calendar.component(.hour, from: date) {
        case 5..<11: .breakfast
        case 11..<15: .lunch
        case 17..<22: .dinner
        default: .snack
        }
    }
}

struct MealValue: Codable, Identifiable, Equatable, Sendable {
    var id = UUID()
    var day: DayKey
    var timestamp: Date
    var timeZoneID: String = TimeZone.current.identifier
    var category: MealCategory
    var notes = ""
    var imageName: String
    var createdAt = Date()
    var updatedAt = Date()
    var localTimeLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.timeZone = TimeZone(identifier: timeZoneID) ?? .current
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: timestamp)
    }
}

struct SettingsValue: Codable, Equatable, Sendable {
    var notificationsEnabled = false
    var reminderMinutes = [9 * 60, 14 * 60, 20 * 60]
    var faceIDEnabled = false
    var targetWeight: Double?
    var onboardingComplete = false
    var waterReminders = WaterReminderSettings()

    enum CodingKeys: String, CodingKey {
        case notificationsEnabled, reminderMinutes, faceIDEnabled, targetWeight, onboardingComplete, waterReminders
    }
    init() {}
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        notificationsEnabled = try values.decodeIfPresent(Bool.self, forKey: .notificationsEnabled) ?? false
        reminderMinutes = try values.decodeIfPresent([Int].self, forKey: .reminderMinutes) ?? [540, 840, 1200]
        faceIDEnabled = try values.decodeIfPresent(Bool.self, forKey: .faceIDEnabled) ?? false
        targetWeight = try values.decodeIfPresent(Double.self, forKey: .targetWeight)
        onboardingComplete = try values.decodeIfPresent(Bool.self, forKey: .onboardingComplete) ?? false
        waterReminders = try values.decodeIfPresent(WaterReminderSettings.self, forKey: .waterReminders) ?? WaterReminderSettings()
    }
}

struct WaterReminderSettings: Codable, Equatable, Sendable {
    static let intervals = [30, 60, 120, 240]
    var enabled = false
    var intervalMinutes = 60
    var startMinute = 8 * 60
    var endMinute = 20 * 60
    var isValid: Bool {
        Self.intervals.contains(intervalMinutes) && (0..<1440).contains(startMinute)
            && (0..<1440).contains(endMinute) && startMinute < endMinute
    }
    static func label(for minutes: Int) -> String {
        switch minutes {
        case 30: "Alle 30 Minuten"
        case 120: "Alle 2 Stunden"
        case 240: "Alle 4 Stunden"
        default: "Stündlich"
        }
    }
}

struct PlannedWaterReminder: Equatable, Sendable, Identifiable {
    let minuteOfDay: Int
    var id: String { "balance.water.\(minuteOfDay)" }
    var hour: Int { minuteOfDay / 60 }
    var minute: Int { minuteOfDay % 60 }
}

enum WaterReminderPlanner {
    /// One repeating calendar request per local time keeps the entire daily window active.
    static func plan(settings: WaterReminderSettings) -> [PlannedWaterReminder] {
        guard settings.enabled, settings.isValid else { return [] }
        return stride(from: settings.startMinute, through: settings.endMinute, by: settings.intervalMinutes)
            .map { PlannedWaterReminder(minuteOfDay: $0) }
    }
}

enum BalanceError: LocalizedError {
    case invalidWeight, invalidRating, invalidImage, missingPhoto, invalidReminder, photoTooLarge, invalidMeasurement
    case invalidWaterReminder, pastDayReadOnly
    var errorDescription: String? {
        switch self {
        case .invalidWeight: "Bitte gib ein gültiges Gewicht zwischen 1 und 700 kg ein."
        case .invalidRating: "Bewertungen müssen zwischen 1 und 5 liegen."
        case .invalidMeasurement: "Bitte gib einen gültigen Umfang zwischen 0,1 und 500 cm ein."
        case .invalidImage: "Dieses Bild konnte nicht gelesen werden. Bitte wähle ein anderes Foto."
        case .missingPhoto: "Bitte füge ein Mahlzeitenfoto hinzu."
        case .invalidReminder: "Bitte wähle drei gültige Erinnerungszeiten."
        case .invalidWaterReminder: "Bitte wähle ein gültiges Intervall und eine Endzeit nach der Startzeit."
        case .pastDayReadOnly: "Vergangene Tage können nur angesehen werden. Änderungen sind nur für heute möglich."
        case .photoTooLarge: "Die Bilddatei ist zu groß. Bitte wähle ein kleineres Foto."
        }
    }
}

enum WeightInput {
    static func parse(_ text: String) throws -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return nil }
        let normalized = trimmed.replacingOccurrences(of: ",", with: ".")
        guard normalized.range(of: #"^\d{1,3}(\.\d{1,3})?$"#, options: .regularExpression) != nil,
              let number = Double(normalized), number.isFinite, (1...700).contains(number)
        else { throw BalanceError.invalidWeight }
        return number
    }
}

struct PlannedReminder: Equatable, Sendable, Identifiable {
    let id: String
    let day: DayKey
    let slot: Int
    let fireDate: Date
    let hour: Int
    let minute: Int
}

enum ReminderPlanner {
    static let horizonDays = 20
    static func plan(now: Date, calendar inputCalendar: Calendar = .current,
                     settings: SettingsValue, documented: Set<DayKey>) -> [PlannedReminder] {
        guard settings.notificationsEnabled, settings.reminderMinutes.count == 3,
              settings.reminderMinutes.allSatisfy({ (0..<1440).contains($0) }) else { return [] }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = inputCalendar.timeZone
        let start = calendar.startOfDay(for: now)
        var result: [PlannedReminder] = []
        for offset in 0..<horizonDays {
            guard let date = calendar.date(byAdding: .day, value: offset, to: start) else { continue }
            let day = DayKey(date, calendar: calendar)
            guard !documented.contains(day) else { continue }
            for (slot, minutes) in settings.reminderMinutes.enumerated() {
                // nextTime handles nonexistent spring hours; first prevents a duplicate in autumn.
                guard let fire = calendar.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0,
                                               of: date, matchingPolicy: .nextTime,
                                               repeatedTimePolicy: .first, direction: .forward),
                      calendar.isDate(fire, inSameDayAs: date), fire > now else { continue }
                result.append(PlannedReminder(id: "balance.\(day.rawValue).\(slot)", day: day, slot: slot,
                                              fireDate: fire, hour: calendar.component(.hour, from: fire),
                                              minute: calendar.component(.minute, from: fire)))
            }
        }
        return result.sorted { $0.fireDate < $1.fireDate }.prefix(60).map { $0 }
    }
}

struct ChartPoint: Identifiable, Equatable, Sendable {
    let day: DayKey
    let value: Double
    var id: String { day.rawValue }
    var date: Date { day.date() }
}

enum Trends {
    static func points(_ measurements: [BodyMeasurements], measurement: BodyMeasurement) -> [ChartPoint] {
        measurements.sorted { $0.day < $1.day }.compactMap { entry in
            guard let value = entry[measurement], value.isFinite else { return nil }
            return ChartPoint(day: entry.day, value: value)
        }
    }
    static func points(_ entries: [DailyValue], metric: Metric? = nil) -> [ChartPoint] {
        entries.sorted { $0.day < $1.day }.compactMap { entry in
            let value: Double?
            if let metric { value = entry[metric].map(Double.init) }
            else { value = entry.weight }
            guard let value, value.isFinite else { return nil }
            return ChartPoint(day: entry.day, value: value)
        }
    }
}
