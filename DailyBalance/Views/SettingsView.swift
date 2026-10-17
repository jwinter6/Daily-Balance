import SwiftUI
import UserNotifications

struct ShareRoute: Identifiable { let id = UUID(); let url: URL }

struct SettingsView: View {
    @Environment(AppStore.self) private var store
    @Environment(LockService.self) private var lock
    @Environment(\.openURL) private var openURL
    @State private var target = ""
    @State private var confirmErase = false
    @State private var share: ShareRoute?
    @State private var working = false
    @State private var feedback: String?
    var body: some View {
        Form {
            Section {
                HStack(spacing: 14) {
                    Image("BrandLogo").resizable().scaledToFit().frame(width: 56, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: 13)).accessibilityLabel("Daily Balance App-Logo")
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Daily Balance").font(.title2.weight(.semibold))
                    }
                }.padding(.vertical, 8)
            }
            Section {
                Toggle("Tägliche Erinnerungen", isOn: Binding(get: { store.settings.notificationsEnabled }, set: enableReminders))
                ForEach(0..<3, id: \.self) { slot in
                    DatePicker(["Morgens", "Mittags", "Abends"][slot], selection: reminderBinding(slot), displayedComponents: .hourAndMinute)
                        .disabled(!store.settings.notificationsEnabled)
                }
            } header: { Text("Tägliche Erinnerungen") } footer: {
                Text("Der erste gespeicherte Eintrag beendet die Check-in-Erinnerungen für diesen Tag. Die nächsten Termine werden beim Öffnen der App erneuert.")
            }
            Section {
                Toggle("An Wasser trinken erinnern", isOn: Binding(get: { store.settings.waterReminders.enabled }, set: enableWaterReminders))
                    .accessibilityIdentifier("waterEnabled")
                Picker("Intervall", selection: Binding(get: { store.settings.waterReminders.intervalMinutes }, set: { interval in
                    var value = store.settings; value.waterReminders.intervalMinutes = interval; persist(value)
                })) {
                    ForEach(WaterReminderSettings.intervals, id: \.self) { minutes in
                        Text(WaterReminderSettings.label(for: minutes)).tag(minutes)
                    }
                }.accessibilityIdentifier("waterInterval").disabled(!store.settings.waterReminders.enabled)
                DatePicker("Von", selection: waterTimeBinding(start: true), displayedComponents: .hourAndMinute)
                    .accessibilityIdentifier("waterStart").disabled(!store.settings.waterReminders.enabled)
                DatePicker("Bis", selection: waterTimeBinding(start: false), displayedComponents: .hourAndMinute)
                    .accessibilityIdentifier("waterEnd").disabled(!store.settings.waterReminders.enabled)
            } header: { Text("Wasser trinken") } footer: {
                Text("Die erste Erinnerung kommt zur Startzeit, danach im gewählten Abstand bis einschließlich der Endzeit. Außerhalb dieses Zeitraums kommen keine Wasser-Erinnerungen. Sie bleiben auch nach deinem Check-in aktiv.")
            }
            if let issue = store.notificationIssue {
                Section {
                    Text(issue).font(.caption).foregroundStyle(.orange)
                    Button("iOS-Mitteilungen öffnen") {
                        if let url = URL(string: UIApplication.openNotificationSettingsURLString) { openURL(url) }
                    }
                }
            }
            Section("Gewicht") {
                LabeledContent("Einheit", value: "kg")
                HStack {
                    Text("Zielgewicht")
                    TextField("Optional", text: $target).keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                        .accessibilityLabel("Zielgewicht in Kilogramm")
                }
                Button("Zielgewicht speichern") {
                    do {
                        var value = store.settings; value.targetWeight = try WeightInput.parse(target)
                        try store.saveSettings(value); feedback = "Zielgewicht gespeichert."
                    } catch { store.errorMessage = error.localizedDescription }
                }
            }
            Section {
                Toggle("App mit Face ID schützen", isOn: Binding(get: { store.settings.faceIDEnabled }, set: enableLock))
                Label(store.privacyVerified ? "Dateischutz und Backup-Ausschluss geprüft" : "Dateischutz noch nicht bestätigt",
                      systemImage: store.privacyVerified ? "checkmark.shield" : "shield")
                    .font(.caption).foregroundStyle(.secondary)
                NavigationLink("So bleiben deine Daten lokal") { privacyInfo }
            } header: { Text("Datenschutz") } footer: {
                Text("Die Sperre verwendet Face ID oder den Gerätecode. Es gibt kein Konto, keine Analyse und keine Cloud-Synchronisierung.")
            }
            Section {
                Button("Tagesdaten als CSV exportieren") { export(.csv) }
                Button("Einträge als JSON exportieren") { export(.json) }
                Text("Unverschlüsselte Textdateien ohne Bilddateien. JSON enthält Mahlzeiten-Metadaten und interne Bildnamen. Die Weitergabe bestimmst du im Teilen-Menü. Dies ist kein vollständiges, wiederherstellbares Backup.")
                    .font(.caption).foregroundStyle(.secondary)
                Button("Alle Daten endgültig löschen", role: .destructive) { confirmErase = true }
            } header: { Text("Deine Daten") }
            Section {
                LabeledContent("Version", value: "1.2 (3)")
                Text("Ein persönliches Tagebuch zur Dokumentation. Keine medizinischen Diagnosen oder Empfehlungen zur Medikation.")
                    .font(.caption).foregroundStyle(.secondary)
                if let feedback { Text(feedback).font(.caption).foregroundStyle(Color.balanceTeal) }
            }
        }
        .navigationTitle("Mehr").disabled(working || store.isBusy)
        .onAppear { target = store.settings.targetWeight.map { String($0).replacingOccurrences(of: ".", with: ",") } ?? "" }
        .confirmationDialog("Alle Tageswerte, Mahlzeiten, Fotos und Einstellungen unwiderruflich löschen?", isPresented: $confirmErase, titleVisibility: .visible) {
            Button("Alle Daten löschen", role: .destructive) {
                Task {
                    working = true
                    defer { working = false }
                    do { try await store.eraseAll(); target = ""; feedback = "Alle lokalen Daten wurden gelöscht." }
                    catch { store.errorMessage = error.localizedDescription }
                }
            }
        }
        .sheet(item: $share, onDismiss: { try? store.clearExports() }) { route in ShareSheet(url: route.url) }
    }
    private var privacyInfo: some View {
        List {
            Section("Ausschließlich lokal") {
                Text("Tageswerte und Einstellungen liegen in einer lokalen SwiftData-Datenbank. Bilder und Vorschaubilder liegen separat im App-Verzeichnis. Die App enthält keine Netzwerkdienste.")
            }
            Section("Geschützt auf deinem Gerät") {
                Text("Datenbank, Fotos und erzeugte Exporte erhalten vollständigen iOS-Dateischutz. Das Datenverzeichnis und seine Inhalte werden von Backups ausgeschlossen. Das schützt nicht vor jeder Form einer Geräteübertragung oder administrativen Sicherung.")
            }
            Section("Deine Verantwortung für Sicherungen") {
                Text("Bei App-Löschung oder Geräteverlust können alle Einträge verloren gehen. Exporte sind freiwillig und unverschlüsselt. Wählst du im Teilen-Menü einen Cloud-Dienst, verlassen die ausgewählten Exportdaten dein Gerät.")
            }
            Section("Fotos") {
                Text("Neue Fotos werden auf maximal 2.000 Pixel verkleinert und ohne die Metadaten der Quelldatei neu gespeichert. Die App legt keine Fotos in deiner allgemeinen Mediathek ab. Bereits dort vorhandene Originale bleiben von deren eigenen iCloud-Einstellungen abhängig.")
            }
        }.navigationTitle("Lokale Speicherung")
    }
    private func reminderBinding(_ slot: Int) -> Binding<Date> {
        Binding(get: {
            let minutes = store.settings.reminderMinutes[slot]
            return Calendar.current.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: Date()) ?? Date()
        }, set: { date in
            var value = store.settings
            value.reminderMinutes[slot] = Calendar.current.component(.hour, from: date) * 60 + Calendar.current.component(.minute, from: date)
            persist(value)
        })
    }
    private func persist(_ settings: SettingsValue) {
        do { try store.saveSettings(settings) } catch { store.errorMessage = error.localizedDescription }
    }
    private func waterTimeBinding(start: Bool) -> Binding<Date> {
        Binding(get: {
            let minutes = start ? store.settings.waterReminders.startMinute : store.settings.waterReminders.endMinute
            return Calendar.current.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: Date()) ?? Date()
        }, set: { date in
            let minutes = Calendar.current.component(.hour, from: date) * 60 + Calendar.current.component(.minute, from: date)
            var value = store.settings
            if start { value.waterReminders.startMinute = minutes }
            else { value.waterReminders.endMinute = minutes }
            persist(value)
        })
    }
    private func enableReminders(_ enabled: Bool) { enableNotifications(enabled, water: false) }
    private func enableWaterReminders(_ enabled: Bool) { enableNotifications(enabled, water: true) }
    private func enableNotifications(_ enabled: Bool, water: Bool) {
        func update() {
            var value = store.settings
            if water { value.waterReminders.enabled = enabled } else { value.notificationsEnabled = enabled }
            persist(value)
        }
        if !enabled { update(); return }
        working = true
        Task {
            defer { working = false }
            do {
                _ = try await store.notifications.requestPermission()
                update()
                await store.reconcileNotifications()
            } catch { store.errorMessage = error.localizedDescription }
        }
    }
    private func enableLock(_ enabled: Bool) {
        if !enabled { var value = store.settings; value.faceIDEnabled = false; persist(value); return }
        working = true
        Task {
            defer { working = false }
            if await lock.authenticate() {
                var value = store.settings; value.faceIDEnabled = true; persist(value)
            } else { store.errorMessage = lock.message }
        }
    }
    private func export(_ format: ExportFormat) {
        do { share = ShareRoute(url: try ExportService.create(format: format, store: store)) }
        catch { store.errorMessage = error.localizedDescription }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
