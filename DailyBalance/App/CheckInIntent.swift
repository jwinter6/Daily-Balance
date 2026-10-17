import AppIntents
import Foundation

struct OpenCheckInIntent: AppIntent {
    static var title: LocalizedStringResource = "Täglichen Check-in öffnen"
    static var description = IntentDescription("Öffnet deinen heutigen Check-in in Daily Balance.")
    static var openAppWhenRun: Bool = true
    static var authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    @MainActor func perform() async throws -> some IntentResult {
        NotificationCenter.default.post(name: .balanceOpenToday, object: nil)
        return .result()
    }
}

struct BalanceShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: OpenCheckInIntent(), phrases: ["Öffne meinen Check-in in \(.applicationName)"],
                    shortTitle: "Check-in öffnen", systemImageName: "leaf")
    }
}
