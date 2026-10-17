import Foundation
import Observation
import SwiftData

@MainActor @Observable final class AppStore {
    private(set) var entries: [DailyValue] = []
    private(set) var meals: [MealValue] = []
    private(set) var bodyMeasurements: [BodyMeasurements] = []
    private(set) var settings = SettingsValue()
    private(set) var isBusy = false
    var errorMessage: String?
    var notificationIssue: String?
    let images: ImageStorageService
    let paths: StoragePaths
    let container: ModelContainer
    let notifications: any ReminderScheduling
    private(set) var currentDay: DayKey
    private let now: () -> Date
    private var context: ModelContext { container.mainContext }
    private(set) var privacyVerified = false

    init(paths: StoragePaths, container: ModelContainer, notifications: (any ReminderScheduling)? = nil, now: @escaping () -> Date = Date.init) throws {
        self.paths = paths; self.container = container; self.now = now; self.currentDay = DayKey(now())
        self.notifications = notifications ?? NotificationService()
        images = ImageStorageService(directory: paths.photos)
        try reload()
    }
    private func reload(days: Bool = true, food: Bool = true, preferences: Bool = true, measurements: Bool = true) throws {
        if days {
            entries = try context.fetch(FetchDescriptor<DailyEntry>(sortBy: [SortDescriptor(\.dayKey)])).map(\.value)
        }
        if food {
            meals = try context.fetch(FetchDescriptor<MealEntry>(sortBy: [SortDescriptor(\.timestamp)])).map(\.value)
        }
        if measurements {
            bodyMeasurements = try context.fetch(FetchDescriptor<BodyMeasurementEntry>(sortBy: [SortDescriptor(\.dayKey)])).map(\.value)
        }
        if preferences {
            let saved = try context.fetch(FetchDescriptor<AppSettings>()).first
            settings = try saved?.value ?? SettingsValue()
        }
    }
    func entry(for day: DayKey) -> DailyValue? { entries.first { $0.day == day } }
    func meals(for day: DayKey) -> [MealValue] { meals.filter { $0.day == day } }
    func measurements(for day: DayKey) -> BodyMeasurements? { bodyMeasurements.first { $0.day == day } }
    func weeklyMeasurements(for day: DayKey) -> BodyMeasurements? {
        let week = WeekKey(day)
        return bodyMeasurements.first { $0.week == week }
    }
    var documentedDays: Set<DayKey> {
        Set(entries.filter(\.isDocumented).map(\.day)).union(meals.map(\.day))
            .union(bodyMeasurements.filter(\.isDocumented).map(\.day))
    }
    func canEdit(_ day: DayKey) -> Bool { day == currentDay && day == DayKey(now()) }
    func canEditMeasurements(for day: DayKey) -> Bool {
        canEdit(day) && weeklyMeasurements(for: day).map { canEdit($0.day) } != false
    }
    private func requireToday(_ day: DayKey) throws {
        guard canEdit(day) else { throw BalanceError.pastDayReadOnly }
    }
    func saveMeasurements(_ draft: BodyMeasurements) throws {
        try requireToday(draft.day)
        guard canEditMeasurements(for: draft.day) else { throw BalanceError.pastDayReadOnly }
        let value = try draft.validated()
        let key = value.week.rawValue
        do {
            let record = try context.fetch(FetchDescriptor<BodyMeasurementEntry>(predicate: #Predicate { $0.weekKey == key })).first
            if !value.isDocumented {
                if let record { context.delete(record) }
            } else if let record { record.apply(value) }
            else { context.insert(BodyMeasurementEntry(value)) }
            try context.save()
        } catch { context.rollback(); throw error }
        try reload(days: false, food: false, preferences: false)
        afterChange()
    }
    func save(_ draft: DailyValue) throws {
        try requireToday(draft.day)
        var value = try draft.validated()
        value.notes = value.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let key = value.day.rawValue
        do {
            let record = try context.fetch(FetchDescriptor<DailyEntry>(predicate: #Predicate { $0.dayKey == key })).first
            if !value.isDocumented {
                if let record { context.delete(record) }
            } else if let record { record.apply(value) }
            else { context.insert(DailyEntry(value)) }
            try context.save()
        } catch { context.rollback(); throw error }
        try reload(food: false, preferences: false, measurements: false)
        afterChange()
    }
    func saveMeal(_ draft: MealValue, imageData: Data?) async throws {
        guard !isBusy else { return }
        isBusy = true
        defer { isBusy = false }
        try requireToday(draft.day)
        if let original = meals.first(where: { $0.id == draft.id }) { try requireToday(original.day) }
        var value = draft
        var newImage: String?
        let oldImage = meals.first { $0.id == draft.id }?.imageName
        if let imageData {
            let name = try await images.save(imageData)
            newImage = name; value.imageName = name
        }
        guard !value.imageName.isEmpty else { throw BalanceError.missingPhoto }
        do {
            // Image preparation can cross midnight while awaiting the image actor.
            try requireToday(value.day)
            let id = value.id
            let record = try context.fetch(FetchDescriptor<MealEntry>(predicate: #Predicate { $0.id == id })).first
            if let record { record.apply(value) } else { context.insert(MealEntry(value)) }
            try context.save()
        } catch {
            context.rollback()
            if let newImage { try? await images.delete(newImage) }
            throw error
        }
        try reload(days: false, preferences: false, measurements: false)
        afterChange()
        if let oldImage, oldImage != value.imageName { try await images.delete(oldImage) }
    }
    func deleteMeal(_ meal: MealValue) async throws {
        guard !isBusy else { return }
        isBusy = true
        defer { isBusy = false }
        try requireToday(meal.day)
        if let original = meals.first(where: { $0.id == meal.id }) { try requireToday(original.day) }
        do {
            let id = meal.id
            for record in try context.fetch(FetchDescriptor<MealEntry>(predicate: #Predicate { $0.id == id })) {
                context.delete(record)
            }
            try context.save()
        } catch { context.rollback(); throw error }
        try reload(days: false, preferences: false, measurements: false)
        afterChange()
        // Commit first: a failed database write can never leave a record pointing at a deleted photo.
        try await images.delete(meal.imageName)
    }
    func saveSettings(_ value: SettingsValue) throws {
        guard value.reminderMinutes.count == 3, value.reminderMinutes.allSatisfy({ (0..<1440).contains($0) })
        else { throw BalanceError.invalidReminder }
        guard value.waterReminders.isValid else { throw BalanceError.invalidWaterReminder }
        if let weight = value.targetWeight, !weight.isFinite || !(1...700).contains(weight) { throw BalanceError.invalidWeight }
        do {
            let record = try context.fetch(FetchDescriptor<AppSettings>()).first
            if let record { record.payload = try JSONEncoder().encode(value) }
            else { context.insert(try AppSettings(value)) }
            try context.save()
        } catch { context.rollback(); throw error }
        settings = value
        afterChange()
    }
    func eraseAll() async throws {
        guard !isBusy else { return }
        isBusy = true
        defer { isBusy = false }
        do {
            for record in try context.fetch(FetchDescriptor<DailyEntry>()) { context.delete(record) }
            for record in try context.fetch(FetchDescriptor<MealEntry>()) { context.delete(record) }
            for record in try context.fetch(FetchDescriptor<AppSettings>()) { context.delete(record) }
            for record in try context.fetch(FetchDescriptor<BodyMeasurementEntry>()) { context.delete(record) }
            var reset = SettingsValue(); reset.onboardingComplete = true
            context.insert(try AppSettings(reset))
            try context.save()
        } catch { context.rollback(); throw error }
        notifications.removeAll()
        try reload()
        try await images.removeOrphans(referenced: [])
        try clearExports()
    }
    func clearExports() throws {
        for url in try FileManager.default.contentsOfDirectory(at: paths.exports, includingPropertiesForKeys: nil) {
            try FileManager.default.removeItem(at: url)
        }
    }
    func refreshServices() async {
        currentDay = DayKey(now())
        do { try paths.audit(); privacyVerified = true }
        catch { privacyVerified = false; errorMessage = "Dateischutz konnte nicht geprüft werden: \(error.localizedDescription)" }
        await reconcileNotifications()
    }
    func startupCleanup() async {
        isBusy = true
        defer { isBusy = false }
        do {
            try await images.removeOrphans(referenced: Set(meals.map(\.imageName)))
            try clearExports()
        } catch { errorMessage = error.localizedDescription }
        await refreshServices()
    }
    private func afterChange() {
        Task { await refreshServices() }
    }
    func reconcileNotifications() async {
        do {
            try await notifications.reconcile(settings: settings, documented: documentedDays)
            let status = await notifications.status()
            notificationIssue = (settings.notificationsEnabled || settings.waterReminders.enabled) && status == .denied
                ? "Mitteilungen sind in iOS deaktiviert. Du kannst sie in den Systemeinstellungen erlauben." : nil
        } catch { notificationIssue = "Erinnerungsplanung fehlgeschlagen: \(error.localizedDescription)" }
    }
}
