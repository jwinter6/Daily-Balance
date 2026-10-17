import Foundation
import SwiftData

@Model final class DailyEntry {
    @Attribute(.unique) var dayKey: String
    var id: UUID
    var weight: Double?
    var mood: Int?
    var energy: Int?
    var sleep: Int?
    var hunger: Int?
    var cravings: Int?
    var notes: String
    var createdAt: Date
    var updatedAt: Date

    init(_ value: DailyValue) {
        dayKey = value.day.rawValue; id = value.id; weight = value.weight
        mood = value.mood; energy = value.energy; sleep = value.sleep
        hunger = value.hunger; cravings = value.cravings; notes = value.notes
        createdAt = value.createdAt; updatedAt = value.updatedAt
    }
    func apply(_ value: DailyValue) {
        weight = value.weight; mood = value.mood; energy = value.energy
        sleep = value.sleep; hunger = value.hunger; cravings = value.cravings
        notes = value.notes; updatedAt = Date()
    }
    var value: DailyValue {
        DailyValue(id: id, day: DayKey(rawValue: dayKey), weight: weight, mood: mood,
                   energy: energy, sleep: sleep, hunger: hunger, cravings: cravings,
                   notes: notes, createdAt: createdAt, updatedAt: updatedAt)
    }
}

@Model final class MealEntry {
    @Attribute(.unique) var id: UUID
    var dayKey: String
    var timestamp: Date
    var timeZoneID: String
    var category: String
    var notes: String
    var imageName: String
    var createdAt: Date
    var updatedAt: Date
    init(_ value: MealValue) {
        id = value.id; dayKey = value.day.rawValue; timestamp = value.timestamp
        timeZoneID = value.timeZoneID; category = value.category.rawValue
        notes = value.notes; imageName = value.imageName
        createdAt = value.createdAt; updatedAt = value.updatedAt
    }
    func apply(_ value: MealValue) {
        dayKey = value.day.rawValue; timestamp = value.timestamp; timeZoneID = value.timeZoneID
        category = value.category.rawValue; notes = value.notes; imageName = value.imageName
        updatedAt = Date()
    }
    var value: MealValue {
        MealValue(id: id, day: DayKey(rawValue: dayKey), timestamp: timestamp,
                  timeZoneID: timeZoneID, category: MealCategory(rawValue: category) ?? .other,
                  notes: notes, imageName: imageName, createdAt: createdAt, updatedAt: updatedAt)
    }
}

@Model final class AppSettings {
    @Attribute(.unique) var key: String
    var payload: Data
    init(_ value: SettingsValue) throws { key = "settings"; payload = try JSONEncoder().encode(value) }
    var value: SettingsValue { get throws { try JSONDecoder().decode(SettingsValue.self, from: payload) } }
}

/// A new, independent entity leaves the existing daily/meal/settings schema unchanged.
@Model final class BodyMeasurementEntry {
    @Attribute(.unique) var weekKey: String
    var dayKey: String
    var id: UUID
    var chest: Double?
    var abdomen: Double?
    var hips: Double?
    var leftThigh: Double?
    var rightThigh: Double?
    var createdAt: Date
    var updatedAt: Date

    init(_ value: BodyMeasurements) {
        weekKey = value.week.rawValue; dayKey = value.day.rawValue; id = value.id
        chest = value.chest; abdomen = value.abdomen; hips = value.hips
        leftThigh = value.leftThigh; rightThigh = value.rightThigh
        createdAt = value.createdAt; updatedAt = value.updatedAt
    }
    func apply(_ value: BodyMeasurements) {
        dayKey = value.day.rawValue
        chest = value.chest; abdomen = value.abdomen; hips = value.hips
        leftThigh = value.leftThigh; rightThigh = value.rightThigh
        updatedAt = Date()
    }
    var value: BodyMeasurements {
        BodyMeasurements(id: id, day: DayKey(rawValue: dayKey), chest: chest,
                         abdomen: abdomen, hips: hips, leftThigh: leftThigh, rightThigh: rightThigh,
                         createdAt: createdAt, updatedAt: updatedAt)
    }
}
