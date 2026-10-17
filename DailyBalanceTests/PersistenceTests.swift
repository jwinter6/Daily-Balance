import XCTest
import SwiftData
import UserNotifications
import UIKit
import ImageIO
@testable import DailyBalance

@MainActor final class TestReminders: ReminderScheduling {
    var documented: Set<DayKey> = []
    var removed = false
    func requestPermission() async throws -> Bool { true }
    func status() async -> UNAuthorizationStatus { .authorized }
    func reconcile(settings: SettingsValue, documented: Set<DayKey>, now: Date) async throws { self.documented = documented }
    func removeAll() { removed = true }
}

@MainActor final class PersistenceTests: XCTestCase {
    private func makeStore(_ path: URL? = nil, now: @escaping () -> Date = Date.init) throws -> AppStore {
        let root = path ?? FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let paths = StoragePaths(root: root)
        try paths.prepare()
        return try AppStore(paths: paths, container: paths.container(), notifications: TestReminders(), now: now)
    }
    private func photo() -> Data {
        UIGraphicsImageRenderer(size: CGSize(width: 100, height: 80)).jpegData(withCompressionQuality: 0.9) { context in
            UIColor.systemTeal.setFill(); context.fill(CGRect(x: 0, y: 0, width: 100, height: 80))
        }
    }
    func testDailyEntryPersistsAcrossReopenedContainerAndUpserts() throws {
        let first = try makeStore(now: { DayKey(rawValue: "2024-01-15").date() })
        var draft = DailyValue(day: DayKey(rawValue: "2024-01-15"))
        draft.weight = 94.6; draft.mood = 4
        try first.save(draft)
        var edit = DailyValue(day: draft.day); edit.weight = 94.2; edit.mood = 5
        try first.save(edit)
        let reopened = try makeStore(first.paths.root)
        XCTAssertEqual(reopened.entries.count, 1)
        XCTAssertEqual(reopened.entries.first?.weight, 94.2)
        XCTAssertEqual(reopened.entries.first?.mood, 5)
        XCTAssertEqual(reopened.entries.first?.id, draft.id)
    }
    func testEmptyDraftDoesNotCreateRecordAndClearingRestoresEligibility() async throws {
        let store = try makeStore()
        let day = DayKey(Date())
        try store.save(DailyValue(day: day))
        XCTAssertTrue(store.entries.isEmpty)
        var entry = DailyValue(day: day); entry.notes = "Gut geschlafen"
        try store.save(entry)
        XCTAssertTrue(store.documentedDays.contains(day))
        try store.save(DailyValue(day: day))
        await store.refreshServices()
        XCTAssertFalse(store.documentedDays.contains(day))
        XCTAssertFalse((store.notifications as! TestReminders).documented.contains(day))
    }
    func testPhotoStoredLocallyStrippedAndDeletedWithThumbnail() async throws {
        let store = try makeStore()
        let now = Date()
        let meal = MealValue(day: DayKey(now), timestamp: now, category: .breakfast, imageName: "")
        try await store.saveMeal(meal, imageData: photo())
        let saved = try XCTUnwrap(store.meals.first)
        let original = store.paths.photos.appendingPathComponent(saved.imageName)
        let thumb = store.paths.photos.appendingPathComponent("thumb_" + saved.imageName)
        XCTAssertTrue(FileManager.default.fileExists(atPath: original.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: thumb.path))
        let data = try Data(contentsOf: original)
        let source = try XCTUnwrap(CGImageSourceCreateWithData(data as CFData, nil))
        let properties = try XCTUnwrap(CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any])
        XCTAssertNil(properties[kCGImagePropertyGPSDictionary as String])
        try await store.deleteMeal(saved)
        XCTAssertFalse(FileManager.default.fileExists(atPath: original.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: thumb.path))
        XCTAssertTrue(store.meals.isEmpty)
    }
    func testReencodingRemovesActualGPSMetadata() async throws {
        let store = try makeStore()
        let source = try XCTUnwrap(CGImageSourceCreateWithData(photo() as CFData, nil))
        let withGPS = NSMutableData()
        let destination = try XCTUnwrap(CGImageDestinationCreateWithData(withGPS, "public.jpeg" as CFString, 1, nil))
        CGImageDestinationAddImageFromSource(destination, source, 0, [
            kCGImagePropertyGPSDictionary: [kCGImagePropertyGPSLatitude: 52.5, kCGImagePropertyGPSLatitudeRef: "N",
                                          kCGImagePropertyGPSLongitude: 13.4, kCGImagePropertyGPSLongitudeRef: "E"]
        ] as CFDictionary)
        XCTAssertTrue(CGImageDestinationFinalize(destination))
        let name = try await store.images.save(withGPS as Data)
        let encoded = try await store.images.read(name, thumbnail: false)
        let result = try XCTUnwrap(CGImageSourceCreateWithData(encoded as CFData, nil))
        let properties = try XCTUnwrap(CGImageSourceCopyPropertiesAtIndex(result, 0, nil) as? [String: Any])
        XCTAssertNil(properties[kCGImagePropertyGPSDictionary as String])
        try await store.images.delete(name)
    }
    func testSeveralMealsChronologicalAndMealAloneCounts() async throws {
        let store = try makeStore()
        let day = DayKey(Date())
        for hour in [19, 8, 12] {
            let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date())!
            let meal = MealValue(day: day, timestamp: date, category: .suggested(at: date), imageName: "")
            try await store.saveMeal(meal, imageData: photo())
        }
        XCTAssertEqual(store.meals.count, 3)
        XCTAssertEqual(store.meals.map(\.timestamp), store.meals.map(\.timestamp).sorted())
        XCTAssertTrue(store.documentedDays.contains(day))
        XCTAssertTrue(store.entries.isEmpty)
    }
    func testReplacingPhotoDeletesOldFilesAndPreservesIdentity() async throws {
        let store = try makeStore()
        let meal = MealValue(day: DayKey(Date()), timestamp: Date(), category: .lunch, imageName: "")
        try await store.saveMeal(meal, imageData: photo())
        let original = store.meals[0]
        var edit = original; edit.notes = "Salat"
        try await store.saveMeal(edit, imageData: photo())
        XCTAssertEqual(store.meals[0].id, original.id)
        XCTAssertNotEqual(store.meals[0].imageName, original.imageName)
        XCTAssertFalse(FileManager.default.fileExists(atPath: store.paths.photos.appendingPathComponent(original.imageName).path))
    }
    func testFailedPhotoImportDoesNotDocumentDay() async throws {
        let store = try makeStore()
        let meal = MealValue(day: DayKey(Date()), timestamp: Date(), category: .other, imageName: "")
        do { try await store.saveMeal(meal, imageData: Data("broken".utf8)); XCTFail("Must reject corrupt image") }
        catch { XCTAssertTrue(store.meals.isEmpty); XCTAssertTrue(store.documentedDays.isEmpty) }
    }
    func testSettingsPersistAndBackupExclusionIsSet() throws {
        let store = try makeStore()
        var settings = SettingsValue(); settings.targetWeight = 85; settings.reminderMinutes = [555, 870, 1215]
        try store.saveSettings(settings)
        let second = try makeStore(store.paths.root)
        XCTAssertEqual(second.settings, settings)
        XCTAssertEqual(try store.paths.root.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup, true)
    }
    func testHardwareFileProtectionIsComplete() throws {
        #if targetEnvironment(simulator)
        throw XCTSkip("Der Simulator liefert keinen Wert für das iOS-Dateischutzattribut. Diese Prüfung erfordert ein physisches iPhone.")
        #else
        let store = try makeStore()
        let attributes = try FileManager.default.attributesOfItem(atPath: store.paths.database.path)
        XCTAssertEqual(attributes[.protectionKey] as? FileProtectionType, .complete)
        #endif
    }
    func testEraseAllRemovesRecordsImagesExportsAndReminders() async throws {
        let store = try makeStore()
        var entry = DailyValue(day: DayKey(Date())); entry.weight = 94
        try store.save(entry)
        var body = BodyMeasurements(day: entry.day); body.chest = 107.5
        try store.saveMeasurements(body)
        try await store.saveMeal(MealValue(day: entry.day, timestamp: Date(), category: .snack, imageName: ""), imageData: photo())
        _ = try ExportService.create(format: .json, store: store)
        try await store.eraseAll()
        XCTAssertTrue(store.entries.isEmpty); XCTAssertTrue(store.meals.isEmpty)
        XCTAssertTrue(store.bodyMeasurements.isEmpty)
        XCTAssertTrue(try FileManager.default.contentsOfDirectory(atPath: store.paths.photos.path).isEmpty)
        XCTAssertTrue(try FileManager.default.contentsOfDirectory(atPath: store.paths.exports.path).isEmpty)
        XCTAssertTrue((store.notifications as! TestReminders).removed)
        XCTAssertFalse(store.settings.notificationsEnabled)
    }
    func testJSONIncludesMealPhotoReferencesAndCSVContainsNoFakeZero() async throws {
        let store = try makeStore(now: { DayKey(rawValue: "2026-01-01").date() })
        var entry = DailyValue(day: DayKey(rawValue: "2026-01-01")); entry.notes = "=SUM(A1:A2)"
        try store.save(entry)
        let json = try ExportService.create(format: .json, store: store)
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        let document = try decoder.decode(ExportDocument.self, from: Data(contentsOf: json))
        XCTAssertEqual(document.dailyEntries.first?.day, entry.day)
        let csv = try String(contentsOf: ExportService.create(format: .csv, store: store), encoding: .utf8)
        XCTAssertTrue(csv.contains("2026-01-01;;;;;;;"))
        XCTAssertTrue(csv.contains("'=SUM(A1:A2)"))
    }
    func testWeeklyMeasurementsCanBeCorrectedOnlyOnTheirMeasurementDay() throws {
        let monday = DayKey(rawValue: "2026-10-12")
        let firstStore = try makeStore(now: { monday.date() })
        var first = BodyMeasurements(day: monday)
        first.chest = 107.5; first.leftThigh = 61.2; first.rightThigh = 62.1
        try firstStore.saveMeasurements(first)
        var correction = first; correction.leftThigh = 60.8
        try firstStore.saveMeasurements(correction)
        let friday = DayKey(rawValue: "2026-10-16")
        let later = try makeStore(firstStore.paths.root, now: { friday.date() })
        var moved = first; moved.day = friday; moved.chest = 100
        XCTAssertThrowsError(try later.saveMeasurements(moved))
        XCTAssertThrowsError(try later.saveMeasurements(BodyMeasurements(day: friday)))
        XCTAssertFalse(later.canEditMeasurements(for: friday))
        let nextMonday = DayKey(rawValue: "2026-10-19")
        let nextStore = try makeStore(firstStore.paths.root, now: { nextMonday.date() })
        var next = BodyMeasurements(day: nextMonday); next.chest = 106
        try nextStore.saveMeasurements(next)
        let reopened = try makeStore(firstStore.paths.root)
        XCTAssertEqual(reopened.bodyMeasurements.count, 2)
        let saved = try XCTUnwrap(reopened.weeklyMeasurements(for: monday))
        XCTAssertEqual(saved.id, first.id); XCTAssertEqual(saved.day, monday)
        XCTAssertEqual(saved.leftThigh, 60.8); XCTAssertEqual(saved.rightThigh, 62.1)
        XCTAssertEqual(reopened.weeklyMeasurements(for: nextMonday)?.chest, 106)
    }
    func testEmptyAndDeletedWeeklyMeasurementsPreserveDailyValuesAndReminderEligibility() async throws {
        let store = try makeStore()
        let day = DayKey(Date())
        try store.saveMeasurements(BodyMeasurements(day: day))
        XCTAssertTrue(store.bodyMeasurements.isEmpty)
        var body = BodyMeasurements(day: day); body.abdomen = 100.4
        try store.saveMeasurements(body)
        await store.refreshServices()
        XCTAssertTrue((store.notifications as! TestReminders).documented.contains(day))
        var daily = DailyValue(day: day); daily.weight = 94.6
        try store.save(daily)
        try store.saveMeasurements(BodyMeasurements(day: day))
        XCTAssertTrue(store.bodyMeasurements.isEmpty)
        XCTAssertEqual(store.entry(for: day)?.weight, 94.6)
        XCTAssertTrue(store.documentedDays.contains(day))
        try store.save(DailyValue(day: day))
        await store.refreshServices()
        XCTAssertFalse((store.notifications as! TestReminders).documented.contains(day))
    }
    func testUpgradeFromOriginalSchemaPreservesWeightPhotosAndSettings() async throws {
        let paths = StoragePaths(root: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        try paths.prepare()
        let imageService = ImageStorageService(directory: paths.photos)
        let image = try await imageService.save(photo())
        let day = DayKey(rawValue: "2026-10-10")
        try autoreleasepool {
            let legacySchema = Schema([DailyEntry.self, MealEntry.self, AppSettings.self])
            let configuration = ModelConfiguration("DailyBalance", schema: legacySchema, url: paths.database, cloudKitDatabase: .none)
            let legacy = try ModelContainer(for: legacySchema, configurations: [configuration])
            let context = legacy.mainContext
            var daily = DailyValue(day: day); daily.weight = 95.2; daily.notes = "Vor dem Update"
            context.insert(DailyEntry(daily))
            context.insert(MealEntry(MealValue(day: day, timestamp: day.date(), category: .lunch, imageName: image)))
            var preferences = SettingsValue(); preferences.targetWeight = 85
            context.insert(try AppSettings(preferences))
            try context.save()
        }
        let upgraded = try makeStore(paths.root, now: { day.date() })
        XCTAssertEqual(upgraded.entries.first?.weight, 95.2)
        XCTAssertEqual(upgraded.entries.first?.notes, "Vor dem Update")
        XCTAssertEqual(upgraded.settings.targetWeight, 85)
        XCTAssertEqual(upgraded.meals.first?.imageName, image)
        XCTAssertTrue(upgraded.bodyMeasurements.isEmpty)
        XCTAssertTrue(FileManager.default.fileExists(atPath: paths.photos.appendingPathComponent(image).path))
        var body = BodyMeasurements(day: day); body.hips = 112.3
        try upgraded.saveMeasurements(body)
        let reopened = try makeStore(paths.root)
        XCTAssertEqual(reopened.weeklyMeasurements(for: day)?.hips, 112.3)
        XCTAssertEqual(reopened.entry(for: day)?.weight, 95.2)
        XCTAssertEqual(reopened.meals.count, 1)
    }
    func testMeasurementExportsContainAllFiveValuesOnlyOnActualMeasurementDay() throws {
        let store = try makeStore(now: { DayKey(rawValue: "2026-10-15").date() })
        var body = BodyMeasurements(day: DayKey(rawValue: "2026-10-15"))
        body.chest = 107.5; body.abdomen = 100.4; body.hips = 112.3
        body.leftThigh = 61.2; body.rightThigh = 62.1
        try store.saveMeasurements(body)
        var daily = DailyValue(day: DayKey(rawValue: "2026-10-16")); daily.weight = 94.6
        let nextDayStore = try makeStore(store.paths.root, now: { daily.day.date() })
        try nextDayStore.save(daily)
        let json = try ExportService.create(format: .json, store: nextDayStore)
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        let document = try decoder.decode(ExportDocument.self, from: Data(contentsOf: json))
        XCTAssertEqual(document.schemaVersion, 2)
        XCTAssertEqual(document.bodyMeasurements.first?.rightThigh, 62.1)
        let csv = try String(contentsOf: ExportService.create(format: .csv, store: nextDayStore), encoding: .utf8)
        XCTAssertTrue(csv.contains("Brustumfang_cm"))
        XCTAssertTrue(csv.contains("107,5;100,4;112,3;61,2;62,1"))
        let dailyRow = try XCTUnwrap(csv.components(separatedBy: "\r\n").first { $0.hasPrefix("2026-10-16;") })
        XCTAssertTrue(dailyRow.hasSuffix(";;;;;"))
    }

    func testPastDailyEditsDeletionAndFutureCreationAreRejected() throws {
        let day = DayKey(rawValue: "2026-10-15")
        let original = try makeStore(now: { day.date() })
        var entry = DailyValue(day: day); entry.weight = 94.6; entry.mood = 4
        try original.save(entry)
        let later = try makeStore(original.paths.root, now: { DayKey(rawValue: "2026-10-16").date() })
        var edit = entry; edit.weight = 80
        XCTAssertThrowsError(try later.save(edit))
        XCTAssertThrowsError(try later.save(DailyValue(day: day)))
        XCTAssertThrowsError(try later.save(DailyValue(day: DayKey(rawValue: "2026-10-17"))))
        XCTAssertEqual(later.entry(for: day)?.weight, 94.6)
        XCTAssertEqual(later.entry(for: day)?.mood, 4)
        var today = DailyValue(day: DayKey(rawValue: "2026-10-16")); today.weight = 94
        XCTAssertNoThrow(try later.save(today))
        var clock = day.date()
        let acrossMidnight = try makeStore(now: { clock })
        try acrossMidnight.save(entry)
        clock = DayKey(rawValue: "2026-10-16").date()
        XCTAssertFalse(acrossMidnight.canEdit(day))
        XCTAssertThrowsError(try acrossMidnight.save(edit))
        XCTAssertEqual(acrossMidnight.entry(for: day)?.weight, 94.6)
    }
    func testPastMealsCannotBeEditedDeletedOrMovedToToday() async throws {
        let day = DayKey(rawValue: "2026-10-15")
        let original = try makeStore(now: { day.date() })
        try await original.saveMeal(MealValue(day: day, timestamp: day.date(), category: .lunch, imageName: ""), imageData: photo())
        let meal = try XCTUnwrap(original.meals.first)
        let later = try makeStore(original.paths.root, now: { DayKey(rawValue: "2026-10-16").date() })
        do { try await later.saveMeal(meal, imageData: photo()); XCTFail("Past meal edit accepted") } catch {}
        var moved = meal; moved.day = DayKey(rawValue: "2026-10-16")
        do { try await later.saveMeal(moved, imageData: nil); XCTFail("Past meal moved") } catch {}
        do { try await later.deleteMeal(meal); XCTFail("Past meal deleted") } catch {}
        XCTAssertEqual(later.meals.first, meal)
        XCTAssertTrue(FileManager.default.fileExists(atPath: later.paths.photos.appendingPathComponent(meal.imageName).path))
    }
    func testCombinedNotificationsKeepWaterAfterCheckInAndRespectCapacity() throws {
        var settings = SettingsValue(); settings.notificationsEnabled = true
        settings.waterReminders.enabled = true
        settings.waterReminders.intervalMinutes = 30
        settings.waterReminders.startMinute = 0; settings.waterReminders.endMinute = 1439
        let now = DayKey(rawValue: "2026-10-16").date()
        let before = NotificationService.requests(settings: settings, documented: [], now: now)
        let after = NotificationService.requests(settings: settings, documented: [DayKey(now)], now: now)
        XCTAssertEqual(before.count, 64); XCTAssertEqual(after.count, 64)
        let water = after.filter { $0.identifier.hasPrefix("balance.water.") }
        XCTAssertEqual(water.count, 48)
        XCTAssertEqual(water.map(\.identifier), before.filter { $0.identifier.hasPrefix("balance.water.") }.map(\.identifier))
        for item in water {
            let trigger = try XCTUnwrap(item.trigger as? UNCalendarNotificationTrigger)
            XCTAssertTrue(trigger.repeats); XCTAssertNil(trigger.dateComponents.day)
            XCTAssertNotNil(trigger.nextTriggerDate())
            XCTAssertEqual(item.content.title, "Wasser trinken")
        }
        XCTAssertFalse(after.contains { $0.identifier.hasPrefix("balance.2026-10-16.") })
        settings.waterReminders.enabled = false
        let withoutWater = NotificationService.requests(settings: settings, documented: [], now: now)
        XCTAssertFalse(withoutWater.contains { $0.identifier.hasPrefix("balance.water.") })
        XCTAssertTrue(withoutWater.allSatisfy { ($0.trigger as? UNCalendarNotificationTrigger)?.repeats == false })
    }
    func testWaterSettingsPersistAndInvalidWindowDoesNotOverwriteSavedValues() throws {
        let store = try makeStore()
        var settings = store.settings; settings.waterReminders.enabled = true
        settings.waterReminders.intervalMinutes = 120
        settings.waterReminders.startMinute = 570; settings.waterReminders.endMinute = 1110
        try store.saveSettings(settings)
        XCTAssertEqual(try makeStore(store.paths.root).settings.waterReminders, settings.waterReminders)
        var invalid = settings; invalid.waterReminders.endMinute = 500
        XCTAssertThrowsError(try store.saveSettings(invalid))
        XCTAssertEqual(store.settings, settings)
    }

}
