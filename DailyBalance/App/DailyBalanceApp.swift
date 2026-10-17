import SwiftUI
import SwiftData

@main
struct DailyBalanceApp: App {
    @State private var store: AppStore?
    @State private var startupError: String?
    @State private var lock = LockService()
    var body: some Scene {
        WindowGroup {
            Group {
                if let store {
                    RootView().environment(store).environment(lock)
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: startupError == nil ? "leaf.circle" : "lock.shield").font(.system(size: 52)).foregroundStyle(Color.balanceTeal)
                        Text(startupError == nil ? "Daily Balance" : "Tagebuch konnte nicht geöffnet werden").font(.title2.weight(.semibold))
                        if let startupError {
                            Text(startupError).font(.subheadline).multilineTextAlignment(.center)
                            Button("Erneut versuchen") { loadStore() }.buttonStyle(.borderedProminent)
                        } else { ProgressView() }
                    }.padding(30).task { if store == nil && startupError == nil { loadStore() } }
                }
            }
            .tint(.balanceTeal)
            .environment(\.locale, Locale(identifier: "de_DE"))
        }
    }
    @MainActor private func loadStore() {
        do {
            let paths: StoragePaths
            #if DEBUG
            if let session = ProcessInfo.processInfo.environment["BALANCE_UI_TEST_SESSION"], UUID(uuidString: session) != nil {
                paths = StoragePaths(root: FileManager.default.temporaryDirectory.appendingPathComponent("UITests/" + session))
                try paths.prepare()
            } else { paths = try StoragePaths.live() }
            #else
            paths = try StoragePaths.live()
            #endif
            let container = try paths.container()
            #if DEBUG
            if let session = ProcessInfo.processInfo.environment["BALANCE_UI_TEST_SESSION"], UUID(uuidString: session) != nil,
               ProcessInfo.processInfo.environment["BALANCE_UI_TEST_PAST_DAY"] == "1",
               try container.mainContext.fetchCount(FetchDescriptor<DailyEntry>()) == 0 {
                let yesterday = DayKey(Calendar.current.date(byAdding: .day, value: -1, to: Date())!)
                var daily = DailyValue(day: yesterday); daily.weight = 95.2; daily.mood = 4; daily.notes = "Vorheriger Tag"
                container.mainContext.insert(DailyEntry(daily))
                var measurements = BodyMeasurements(day: yesterday); measurements.chest = 107.5
                container.mainContext.insert(BodyMeasurementEntry(measurements))
                try container.mainContext.save()
            }
            #endif
            store = try AppStore(paths: paths, container: container)
            startupError = nil
        } catch {
            // Never replace a failed persistent store with an empty or in-memory database.
            startupError = "Entsperre dein iPhone und versuche es erneut. Deine Daten werden nicht zurückgesetzt. Fehler: \(error.localizedDescription)"
        }
    }
}
