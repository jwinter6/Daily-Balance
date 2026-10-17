import SwiftUI

extension Notification.Name { static let balanceOpenToday = Notification.Name("balance.openToday") }

struct RootView: View {
    @Environment(AppStore.self) private var store
    @Environment(LockService.self) private var lock
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab = 0
    @State private var today = DayKey(Date())
    private var isLocked: Bool { store.settings.faceIDEnabled && !lock.unlocked }
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                NavigationStack { DayDashboard(day: today) }
                    .tabItem { Label("Heute", systemImage: "sun.max") }.tag(0)
                NavigationStack { HistoryView() }
                    .tabItem { Label("Verlauf", systemImage: "chart.xyaxis.line") }.tag(1)
                NavigationStack { MealsView() }
                    .tabItem { Label("Essen", systemImage: "fork.knife") }.tag(2)
                NavigationStack { SettingsView() }
                    .tabItem { Label("Mehr", systemImage: "slider.horizontal.3") }.tag(3)
            }
            .disabled(isLocked || store.isBusy)
            .accessibilityHidden(isLocked || scenePhase != .active)
            .blur(radius: isLocked || scenePhase != .active ? 22 : 0)
            if isLocked || scenePhase != .active { lockScreen }
        }
        .fullScreenCover(isPresented: Binding(get: { !store.settings.onboardingComplete && !isLocked }, set: { _ in })) {
            OnboardingView()
        }
        .alert("Hinweis", isPresented: Binding(get: { store.errorMessage != nil }, set: { if !$0 { store.errorMessage = nil } })) {
            Button("OK") { store.errorMessage = nil }
        } message: { Text(store.errorMessage ?? "") }
        .task {
            await store.startupCleanup()
            if isLocked { _ = await lock.authenticate() }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                today = DayKey(Date())
                Task {
                    if isLocked { _ = await lock.authenticate() }
                    await store.refreshServices()
                }
            } else if !lock.authenticating { lock.unlocked = false }
        }
        .onReceive(Timer.publish(every: 30, on: .main, in: .common).autoconnect()) { date in
            guard today != DayKey(date) else { return }
            today = DayKey(date)
            Task { await store.refreshServices() }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            today = DayKey(Date())
            Task { await store.refreshServices() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSSystemTimeZoneDidChange)) { _ in
            today = DayKey(Date())
            Task { await store.refreshServices() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .balanceOpenToday)) { _ in selectedTab = 0 }
        .privacySensitive()
    }
    private var lockScreen: some View {
        VStack(spacing: 18) {
            Image("BrandLogo").resizable().scaledToFit().frame(width: 72, height: 72).clipShape(RoundedRectangle(cornerRadius: 17))
            Text("Daily Balance").font(.title2.weight(.semibold))
            if scenePhase == .active && isLocked {
                Text(lock.message ?? "Entsperre dein Tagebuch mit Face ID oder deinem Gerätecode.")
                    .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                Button("Tagebuch entsperren", systemImage: "faceid") { Task { _ = await lock.authenticate() } }
                    .buttonStyle(.borderedProminent).disabled(lock.authenticating)
            }
        }.padding(32).frame(maxWidth: .infinity, maxHeight: .infinity).background(Color.balanceCanvas)
    }
}

struct OnboardingView: View {
    @Environment(AppStore.self) private var store
    @State private var requesting = false
    @State private var error: String?
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Image("BrandLogo").resizable().scaledToFit().frame(width: 80, height: 80).clipShape(RoundedRectangle(cornerRadius: 18)).padding(.top, 45)
                SectionEyebrow(title: "Willkommen bei Daily Balance")
                Text("Ein kleiner Moment.\nMehr Überblick.").font(.largeTitle.weight(.bold)).tracking(-1)
                Text("Halte Gewicht, Wohlbefinden und Mahlzeiten fest. In deinem Tempo. Deine Daten bleiben lokal auf deinem iPhone.")
                    .font(.title3).foregroundStyle(.secondary)
                BalanceCard {
                    Label("Freundlich erinnert", systemImage: "bell.badge").font(.headline)
                    Text("Auf Wunsch erinnern wir dich täglich um 09:00, 14:00 und 20:00 Uhr. Sobald du etwas gespeichert hast, entfallen die weiteren Erinnerungen für diesen Tag.")
                    Text("Du kannst alle Zeiten ändern oder Erinnerungen jederzeit ausschalten.").font(.subheadline).foregroundStyle(.secondary)
                }
                Button("Erinnerungen erlauben") { Task { await finish(requestPermission: true) } }
                    .buttonStyle(.borderedProminent).controlSize(.large).frame(maxWidth: .infinity).accessibilityIdentifier("enableReminders")
                Button("Ohne Erinnerungen starten") { Task { await finish(requestPermission: false) } }
                    .frame(maxWidth: .infinity, minHeight: 44).accessibilityIdentifier("skipReminders")
                if let error { Text(error).font(.caption).foregroundStyle(.red) }
                Text("Kein Konto. Keine Cloud. Keine Werbung.").font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity)
            }.padding(26)
        }.journalBackground().interactiveDismissDisabled().disabled(requesting)
    }
    private func finish(requestPermission: Bool) async {
        requesting = true
        defer { requesting = false }
        do {
            let enabled = requestPermission ? try await store.notifications.requestPermission() : false
            var value = store.settings; value.onboardingComplete = true; value.notificationsEnabled = enabled
            try store.saveSettings(value)
        } catch { self.error = error.localizedDescription }
    }
}
