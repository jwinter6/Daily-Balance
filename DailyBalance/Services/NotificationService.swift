import Foundation
import UserNotifications

@MainActor protocol ReminderScheduling {
    func requestPermission() async throws -> Bool
    func status() async -> UNAuthorizationStatus
    func reconcile(settings: SettingsValue, documented: Set<DayKey>, now: Date) async throws
    func removeAll()
}

extension ReminderScheduling {
    func reconcile(settings: SettingsValue, documented: Set<DayKey>) async throws {
        try await reconcile(settings: settings, documented: documented, now: Date())
    }
}

@MainActor final class NotificationService: ReminderScheduling {
    private let center = UNUserNotificationCenter.current()
    private var revision = 0
    private var running = false
    private var latest: (settings: SettingsValue, documented: Set<DayKey>, now: Date)?
    static let messages = [
        "Guten Morgen! Wie fühlst du dich heute? Ein kurzer Check-in genügt.",
        "Schon einen Moment für deinen heutigen Eintrag gefunden?",
        "Ein kurzer Tagesrückblick? Halte fest, wie dein Tag war."
    ]
    func requestPermission() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .sound])
    }
    func status() async -> UNAuthorizationStatus { await center.notificationSettings().authorizationStatus }

    /// Coalesce rapid saves into a single serial reconciliation; never race two add/remove passes.
    func reconcile(settings: SettingsValue, documented: Set<DayKey>, now: Date = Date()) async throws {
        revision += 1
        latest = (settings, documented, now)
        guard !running else { return }
        running = true
        defer { running = false }
        while let input = latest {
            latest = nil
            try await apply(settings: input.settings, documented: input.documented, now: input.now, token: revision)
        }
    }
    private func apply(settings: SettingsValue, documented: Set<DayKey>, now: Date, token: Int) async throws {
        let permission = await status()
        guard token == revision else { return }
        let allowed = permission == .authorized || permission == .provisional || permission == .ephemeral
        let plan = allowed ? Self.requests(settings: settings, documented: documented, now: now) : []
        let pending = await center.pendingNotificationRequests()
        guard token == revision else { return }
        let desiredIDs = Set(plan.map(\.identifier))
        center.removePendingNotificationRequests(withIdentifiers: pending.filter {
            $0.identifier.hasPrefix("balance.") && !desiredIDs.contains($0.identifier)
        }.map(\.identifier))
        let delivered = await center.deliveredNotifications()
        guard token == revision else { return }
        center.removeDeliveredNotifications(withIdentifiers: delivered.filter { notification in
            documented.contains(where: { notification.request.identifier.hasPrefix("balance.\($0.rawValue).") })
        }.map { $0.request.identifier })
        let existing = Dictionary(uniqueKeysWithValues: pending.map { ($0.identifier, $0) })
        for item in plan {
            guard token == revision else { return }
            if let previous = existing[item.identifier],
               let previousTrigger = previous.trigger as? UNCalendarNotificationTrigger,
               let trigger = item.trigger as? UNCalendarNotificationTrigger,
               previousTrigger.dateComponents == trigger.dateComponents,
               previousTrigger.repeats == trigger.repeats,
               previous.content.body == item.content.body { continue }
            try await center.add(item)
            // A reset can arrive while add is awaiting completion.
            if token != revision && latest == nil { center.removePendingNotificationRequests(withIdentifiers: [item.identifier]) }
        }
    }
    /// Reserve space for all water times before filling the rolling check-in window.
    static func requests(settings: SettingsValue, documented: Set<DayKey>, now: Date,
                         calendar: Calendar = .current) -> [UNNotificationRequest] {
        let water = WaterReminderPlanner.plan(settings: settings.waterReminders).map { item in
            let content = UNMutableNotificationContent()
            content.title = "Wasser trinken"
            content.body = "Zeit für ein Glas Wasser."
            content.sound = .default
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: DateComponents(hour: item.hour, minute: item.minute), repeats: true)
            return UNNotificationRequest(identifier: item.id, content: content, trigger: trigger)
        }
        let daily = ReminderPlanner.plan(now: now, calendar: calendar, settings: settings, documented: documented)
            .prefix(64 - water.count).map { item in
                let content = UNMutableNotificationContent()
                content.title = "Dein täglicher Moment"
                content.body = Self.messages[item.slot]
                content.sound = .default
                let civil = item.day.rawValue.split(separator: "-").compactMap { Int($0) }
                let components = DateComponents(year: civil[0], month: civil[1], day: civil[2],
                                                hour: item.hour, minute: item.minute)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                return UNNotificationRequest(identifier: item.id, content: content, trigger: trigger)
            }
        return water + daily
    }
    func removeAll() {
        revision += 1; latest = nil
        center.removeAllPendingNotificationRequests(); center.removeAllDeliveredNotifications()
    }
}
