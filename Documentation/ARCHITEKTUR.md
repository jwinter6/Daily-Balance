# Technische Dokumentation · Daily Balance

Ein natives, deutschsprachiges iPhone-Tagebuch für Gewicht, wöchentliche Körpermaße, Wohlbefinden, Schlaf, Energie, Hunger, Cravings und Mahlzeitenfotos. SwiftUI, SwiftData, Swift Charts, UserNotifications, PhotosUI, AVFoundation, LocalAuthentication und App Intents. Keine externen Bibliotheken, Registrierung oder Backend-Dienste.

## Projekt öffnen

`DailyBalance.xcodeproj` in Xcode öffnen, Scheme **DailyBalance** auswählen und ein Zielgerät wählen. Das Projekt ist vollständig enthalten; ein Projektgenerator ist zum Öffnen und Bauen nicht nötig.

- Mindestversion: **iOS 17.0**, iPhone, Hochformat.
- Geprüfte Werkzeugkette: **Xcode 27.1**, Swift 6.4 im Swift-5-Sprachmodus, iOS-SDK 27.1.
- Verwende eine Xcode-Version, die die iOS-Version deines iPhone 18 Pro unterstützt.
- Keine Swift-Package-Abhängigkeiten. `Package.swift` dient ausschließlich den unabhängig ausführbaren Kernlogiktests.
- Die App startet mit einem leeren Tagebuch. Es werden keine Beispieldaten als persönliche Daten angelegt.

## Implementierte Funktionen

**Neu in Version 1.2:** Separate Wasser-Erinnerungen alle 30 Minuten, stündlich, alle 2 oder 4 Stunden innerhalb eines frei gewählten Tageszeitraums. Vergangene Tage sind nur lesbar; Änderungen und einzelne Löschungen sind ausschließlich heute möglich. Die Mehr-Seite verwendet das App-Logo. Details: [Wasser und abgeschlossene Tage](WASSER-UND-VERLAUF.md).

**Seit Version 1.1:** Brust, Bauch, Po und beide Oberschenkel einmal pro Kalenderwoche in Zentimetern erfassen. Unter **Verlauf → Körpermaße** stehen fünf getrennte interaktive Diagramme bereit. Details: [Körpermaße-Anleitung](KOERPERMASSE.md).

| Bereich | Funktionen |
|---|---|
| Heute | Wochenstatus und Eingabe der Körpermaße; letztes Gewicht, Gewichtseingabe mit deutschem Dezimalkomma, fünf unabhängige Bewertungen, freiwillige Notizen, Mahlzeitenvorschau |
| Verlauf | Getrennte Bereiche für Gewicht/Befinden und fünf Körpermaße-Diagramme in cm; 7, 30, 90 Tage, 1 Jahr oder Gesamt; Startwert, letzter Wert, Veränderung und optionale Ziellinie |
| Kalender | Monatsansicht mit Eintrags- und Mahlzeitenmarkierungen; Tagesdetails öffnen; vergangene Tage nur ansehen |
| Essen | Kamera, System-Fotoauswahl, Kategorien, Beschreibung, Zeitstempel; Tages- und Wochenansicht, Großansicht, Bearbeitung, Fototausch und Löschung |
| Mehr | Drei Check-in-Zeiten und separate Wasser-Erinnerungen mit Intervall und Tageszeitraum, Zielgewicht, Face ID/Gerätecode, lokaler JSON-/CSV-Export und vollständige Datenlöschung |
| Kurzbefehle | „Täglichen Check-in öffnen“ öffnet die Heute-Ansicht; keine Gesundheitswerte werden als Siri-Entitäten bereitgestellt |

Nur der heutige Tag ist bearbeitbar. Vergangene Werte, Notizen, Mahlzeiten und Wochenmessungen können angesehen und exportiert werden; einzelne Änderungen und Löschungen sind gesperrt. Eine Wochenmessung kann nur an ihrem tatsächlichen Messtag korrigiert werden. Die ausdrückliche Funktion „Alle Daten endgültig löschen“ bleibt verfügbar.

Bewertungen speichern mit einem Tippen. Ein erneutes Tippen auf den ausgewählten Wert entfernt ihn. Gewicht und Notizen werden im Bearbeitungsfenster ausdrücklich gespeichert; Abbrechen verwirft den Entwurf. Ein leeres Gewichtsfeld entfernt nur den Gewichtswert. „Tageswerte löschen“ entfernt die Bewertungen und Notizen, lässt Mahlzeiten aber erhalten.

Die App dokumentiert persönliche Angaben. Sie erstellt keine Diagnosen, Dosisempfehlungen, Kalorienbewertungen oder Gewichtsprognosen.

## Auf dem iPhone installieren

Eine ausführliche Klick-für-Klick-Anleitung für Signing-Team, Apple-Account und Geräteauswahl steht in [Documentation/INSTALLATION.md](INSTALLATION.md).

1. Xcode einmal öffnen und gegebenenfalls die angezeigten Lizenz- und Komponenten-Schritte selbst abschließen. Unter **Xcode → Settings → Platforms/Components** die benötigte iOS-Unterstützung installieren.
2. Unter **Xcode → Settings → Apple Accounts** deine Apple-ID hinzufügen.
3. `DailyBalance.xcodeproj` öffnen. Im Projektnavigator das Projekt und anschließend das Target **DailyBalance** auswählen.
4. Unter **Signing & Capabilities** „Automatically manage signing“ aktiv lassen und dein **Team** auswählen. Eine Team-ID ist absichtlich nicht im gelieferten Projekt hinterlegt.
5. Falls die Bundle-ID bereits belegt ist, `de.jan.dailybalance` unter **Bundle Identifier** durch eine eigene eindeutige Kennung ersetzen. Bei Verwendung der Test-Targets deren Kennungen ebenfalls anpassen.
6. Das iPhone 18 Pro per Kabel mit dem Mac verbinden, entsperren und die Vertrauensabfragen bestätigen. Danach kann bei passender Xcode-Konfiguration auch die drahtlose Entwicklung verwendet werden.
7. Falls iOS dazu auffordert: **Einstellungen → Datenschutz & Sicherheit → Entwicklermodus** aktivieren und die vorgesehenen Neustart-/Bestätigungsschritte ausführen.
8. In Xcode das iPhone als Run Destination und **DailyBalance** als Scheme auswählen. Mit **⌘R** kompilieren, signieren und installieren.
9. Gegebenenfalls unter **Einstellungen → Allgemein → VPN & Geräteverwaltung** dem eigenen Entwicklerprofil vertrauen, falls iOS diesen Schritt verlangt.
10. Beim ersten Start entscheiden, ob lokale Mitteilungen erlaubt werden sollen. Kamera und Face ID werden erst bei Verwendung der jeweiligen Funktion angefragt. Die System-Fotoauswahl benötigt keinen pauschalen Zugriff auf die gesamte Mediathek.

Für persönliche Entwicklung kann Xcode ein „Personal Team“ einer Apple-ID verwenden. Kostenlose Entwicklungsprofile sind zeitlich und funktionell beschränkt; Xcode zeigt die jeweils geltenden Bedingungen und nötige Erneuerungen an. Für TestFlight und reguläre Verteilung wird eine passende Apple-Developer-Mitgliedschaft benötigt. Dieses Paket enthält keinen Verteilungsschlüssel und keine signierte IPA.

**Die erfolgreichen Builds wurden ohne Code-Signing erstellt. Installation und Verhalten auf einem physischen iPhone sind damit noch nicht bestätigt.**

## Technische Architektur

```text
DailyBalance/
├── DailyBalance.xcodeproj/             Vollständiges Projekt und gemeinsames Scheme
├── DailyBalance/
│   ├── App/                           App-Start, Tab-Navigation, Sperre, Onboarding, App Intent
│   ├── Models/                        Foundation-Domäne und SwiftData-Modelle
│   ├── Services/                      Transaktionen, Fotos, Erinnerungen, Export, Dateischutz
│   ├── Views/                         Tagesansicht, Editor, Verlauf, Essen, Einstellungen
│   ├── Components/                    Karten, Bewertungen, Kalender, Bilder, Sichtschutz
│   └── Resources/                     Info.plist, Datenschutzmanifest, App-Icon
├── CoreTests/                         31 Tests der plattformunabhängigen Geschäftslogik
├── DailyBalanceTests/                 18 iOS-Integrationstests und 1 Geräte-Dateischutztest
├── DailyBalanceUITests/               7 UI-Tests
├── Scripts/                           Reproduzierbare Projekt-, Icon- und Compilerwerkzeuge
├── Documentation/                     Prüfprotokoll und Build-Nachweise
└── Package.swift                      Unabhängiges Foundation-Testpaket
```

`AppStore` ist ein `@MainActor @Observable`-Dienst. Views bearbeiten Wert-Entwürfe statt dauerhaft gebundener Datenbankobjekte. Datenbankänderungen werden ausdrücklich gespeichert; bei Fehlern wird die Transaktion zurückgerollt. Automatisches SwiftData-Speichern ist deaktiviert. Ein fehlgeschlagener Datenbankstart ersetzt die vorhandene Datei niemals durch einen leeren Store.

SwiftUI besitzt lokale Auswahl- und Darstellungszustände. Die App enthält vier unabhängige `NavigationStack`s innerhalb einer nativen `TabView`. Das Design verwendet Systemtypografie, SF Symbols, großzügige Karten und Blaugrün/Blau. Systemfarben unterstützen Hell-/Dunkelmodus, Controls besitzen VoiceOver-Beschriftungen und berücksichtigen Dynamic Type. Die App verändert keine Medikamentenpläne.

### Datenmodelle

| Modell | Persistierte Inhalte |
|---|---|
| `DailyEntry` | Eindeutiger `dayKey`, UUID, optionales Gewicht, optionale Bewertungen für Stimmung/Energie/Schlaf/Hunger/Cravings, Notizen, Erstellungs- und Änderungszeit |
| `MealEntry` | UUID, `dayKey`, Zeitstempel, ursprüngliche Zeitzone, Kategorie, Notiz, lokaler Bildname, Erstellungs- und Änderungszeit |
| `AppSettings` | Ein eindeutiger Datensatz mit codiertem `SettingsValue`: Erinnerungen, drei Minutenwerte seit Mitternacht, Sperre, optionales Zielgewicht und Onboardingstatus |
| `BodyMeasurementEntry` | Eindeutiger ISO-`weekKey`, tatsächlicher `dayKey`, UUID, fünf optionale Umfänge in cm und Zeitstempel; ein Eintrag pro Montag–Sonntag-Woche |

Ein `dayKey` ist ein gregorianisches Kalenderdatum wie `2026-10-16`, kein UTC-Mitternachtswert. Der ursprüngliche Tag bleibt bei späteren Reisen erhalten. Pro Tag existiert höchstens ein `DailyEntry`; die Datenbank erzwingt die Eindeutigkeit. Beim Bearbeiten desselben Tages wird dessen Datensatz samt ursprünglicher UUID aktualisiert. Alle Trackingwerte sind optional; fehlende Werte ergeben keine künstlichen Nullen in Diagrammen.

Mahlzeiten behalten ihren ursprünglichen Kalendertag und die ursprüngliche Zeitzone. Die Uhrzeit heutiger Mahlzeiten ist editierbar; eine nachträgliche Datumszuordnung zu vergangenen Tagen ist gesperrt. Die Detailansicht zeigt die ursprüngliche Zeitzone an.

### Lokale Ablage

```text
Library/Application Support/DailyBalance/
├── Balance.store                      SwiftData/SQLite und gegebenenfalls WAL/SHM-Dateien
├── Photos/
│   ├── <UUID>.jpg                     Foto, maximal 2.000 Pixel
│   └── thumb_<UUID>.jpg               Vorschau, maximal 480 Pixel
└── Exports/                           Nur ausdrücklich erzeugte Text-Exporte
```

Die SwiftData-Konfiguration verwendet ausdrücklich `cloudKitDatabase: .none`. Es gibt keine iCloud-/CloudKit-Entitlements, HealthKit-Anbindung, Push-Server oder Netzwerkclients im App-Code. Siehe [Apple: ModelConfiguration](https://developer.apple.com/documentation/swiftdata/modelconfiguration).

`StoragePaths` setzt `NSFileProtectionComplete` und `isExcludedFromBackup` auf das Datenverzeichnis. Fotos, Vorschaubilder und Exporte erhalten diese Eigenschaften auch direkt nach der Dateierzeugung. Die Datenbank und ihre Begleitdateien werden nach dem Öffnen und nach Änderungen erneut berücksichtigt. Die App liest das Backup-Ausschlussattribut des Verzeichnisses zurück; Fehler werden angezeigt.

**Grenze von System-Backups:** Apple beschreibt `isExcludedFromBackup` ausdrücklich als Hinweis an das System, nicht als absolute Garantie, dass Daten nie in einer Sicherung oder auf einem wiederhergestellten Gerät erscheinen. Eine forensisch überprüfte iCloud-/Finder-Sicherung wurde hier nicht erstellt. Die App kann administrierte Sicherungen, Geräteübertragungen und vom Nutzer weitergegebene Exporte nicht vollständig kontrollieren. Siehe [Apple: Optimizing Your App’s Data for iCloud Backup](https://developer.apple.com/documentation/foundation/optimizing-your-app-s-data-for-icloud-backup).

Durch den gewünschten Backup-Ausschluss kann die Wiederherstellung bei Geräteverlust oder App-Deinstallation unmöglich sein. Die aktuell enthaltenen Text-Exporte ersetzen keine vollständige Fotosicherung.

### Fotoverwaltung

- Kamera über native iOS-Kameraoberfläche und vorherige Kamera-Berechtigungsprüfung; keine automatische Ablage in der allgemeinen Mediathek.
- Import über den System-Picker; nur das aktiv ausgewählte Bild wird übernommen. Ein bereits in iCloud-Fotos liegendes Original kann der System-Picker dafür herunterladen. Dessen ursprüngliche Cloud-Einstellungen verändert die App nicht.
- `ImageStorageService` ist ein Actor. Dekodierung, Größenanpassung, JPEG-Kompression und Dateiarbeit für gespeicherte Bilder erfolgen abseits des Main Actors.
- ImageIO rendert die Orientierung in die Pixel und erstellt eine neue JPEG-Datei ohne Übernahme der ursprünglichen EXIF-/GPS-Eigenschaften. JPEG-Qualität: 0,82 für das Foto und 0,72 für die Vorschau.
- UUID-Dateinamen, atomare Schreibvorgänge, maximale Quelldateigröße 60 MB.
- Kalender und Übersichten laden Vorschaubilder bei Bedarf. Hochaufgelöste Fotos werden nur für die jeweilige Einzelansicht geladen; es werden nicht alle Bilder gleichzeitig dekodiert.
- Die Datenbank speichert ausschließlich Dateinamen und Metadaten. Tagesänderungen laden Mahlzeitenmetadaten nicht unnötig erneut.
- Neue Dateien werden vor der Datenbanktransaktion erstellt und bei deren Fehlschlag entfernt. Bei Ersatz oder Löschung wird zuerst die Datenbankänderung gespeichert und danach die alte Datei entfernt. Verbliebene unreferenzierte Dateien werden beim nächsten Start bereinigt.

### Erinnerungslogik

Standard: **09:00, 14:00, 20:00**, einzeln veränderbar. Benachrichtigungsrechte werden nach einer Erklärung angefragt. Die App plant datumsbezogene, nicht wiederholende `UNCalendarNotificationTrigger` über `UNUserNotificationCenter`.

Ein Tag gilt als dokumentiert, wenn ein Gewicht, eine Bewertung, eine Notiz, eine Mahlzeit oder Körpermaße mit diesem tatsächlichen Messtag vorhanden sind. Körpermaße werden nur einmal pro Kalenderwoche erfasst und dokumentieren nicht automatisch die anderen Wochentage. Öffnen, leere Entwürfe, abgebrochene Bearbeitung und fehlgeschlagene Fotoimporte zählen nicht.

1. Der reine `ReminderPlanner` betrachtet heute und die nächsten 19 Tage.
2. Für dokumentierte Tage werden keine Erinnerungen vorgesehen; bereits vergangene Uhrzeiten werden ausgelassen.
3. Kennungen sind `balance.JJJJ-MM-TT.SLOT` mit drei Slots pro Tag. Maximal werden **60** Anfragen erzeugt.
4. Der Dienst entfernt überholte Kennungen, behält unveränderte zukünftige Anfragen und ersetzt Anfragen bei geänderten Zeiten.
5. Schnelle aufeinanderfolgende Speichervorgänge werden in einem seriellen Abgleich zusammengefasst, damit sich asynchrone Add-/Remove-Vorgänge nicht überholen.
6. Beim Entfernen des letzten gültigen Eintrags werden verbleibende heutige Uhrzeiten erneut vorgesehen. Andere noch vorhandene Werte oder Fotos halten den Tag weiterhin dokumentiert.
7. Start, erneute Aktivierung und relevante Zeitänderungen erneuern den rollierenden Plan.

Die Systemdokumentation zur früheren lokalen Benachrichtigungs-API nennt eine Grenze von 64 vorgemerkten Mitteilungen; der kombinierte Plan bleibt bei höchstens 64 Anfragen. Wasserzeiten werden zuerst reserviert; verbleibende Plätze gehen an die zeitlich nächsten Check-in-Termine. Verwendet wird ausschließlich die aktuelle UserNotifications-API. Siehe [Apple: UILocalNotification, dokumentierte Begrenzung](https://developer.apple.com/documentation/uikit/uilocalnotification) und [Apple: Scheduling and Handling Local Notifications](https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/SchedulingandHandlingLocalNotifications.html).

Die Trigger tragen keine fest gepinnte Zeitzone und orientieren sich an lokalen Uhrzeiten. Bei der Neuberechnung werden nicht existierende Frühlingszeiten auf den nächsten gültigen Zeitpunkt verschoben und doppelte Herbstzeiten nur einmal geplant. Der aktuelle Plan wird nach einem Zeitzonenwechsel beim nächsten Aktivieren neu abgeglichen. Zeitzonenwechsel ohne anschließendes Aktivieren können insbesondere an Datumsgrenzen nicht vollständig nachgeführt werden; es gibt keinen garantiert laufenden Hintergrundprozess.

Die Auslieferung geplanter Mitteilungen übernimmt iOS auch bei geschlossener App. **Check-in-Erinnerungen werden für höchstens 20 Tage vorgemerkt; bei vielen Wasserzeiten verkürzt sich dieser Vorlauf.** Wasser-Erinnerungen verwenden täglich wiederholende Uhrzeit-Trigger und laufen auch ohne erneutes Öffnen weiter, bis sie ausgeschaltet werden. Fokus, Mitteilungszusammenfassung, entzogene Rechte und Systemeinstellungen können Anzeigen verzögern oder unterdrücken. Die tatsächliche Systemzustellung wurde hier nicht im Simulator oder auf einem Gerät ausgeführt.

### Wasser-Erinnerungen

Ein separater Schalter unter **Mehr → Wasser trinken** aktiviert lokale Trinkhinweise. Intervalle: 30, 60, 120 oder 240 Minuten. Standardfenster: 08:00–20:00 Uhr. Die erste Erinnerung liegt auf der Startzeit; weitere folgen im gewählten Abstand bis maximal zur Endzeit. Die Endzeit muss am selben Tag nach der Startzeit liegen. Ein Intervall, das die Endzeit nicht genau trifft, erzeugt dort keine zusätzliche Erinnerung.

Jede Uhrzeit hat einen täglich wiederholenden `UNCalendarNotificationTrigger` mit Kennung `balance.water.MINUTEN`. Außerhalb des Fensters gibt es keine geplanten Wasserhinweise. Ein Tages-Check-in entfernt ausschließlich die datumsbezogenen Check-in-Hinweise, Wasser bleibt aktiv. Ein geändertes Fenster ersetzt die betroffenen Wasserzeiten; Ausschalten entfernt alle zukünftigen Wasserhinweise. Alte Einstellungen ohne Wasserfelder werden unverändert übernommen und Wasser bleibt zunächst ausgeschaltet.

### App-Sperre

`LocalAuthentication` verwendet `.deviceOwnerAuthentication`: Face ID mit dem systemeigenen Gerätecode als Rückfallmöglichkeit. Aktivieren erfordert eine erfolgreiche Authentifizierung. Die Daten selbst werden von iOS-Dateischutz geschützt; Face ID ersetzt keine separate Datenbankverschlüsselung.

Beim Verlassen der aktiven App werden Inhalte verdeckt. Tageseditor, Mahlzeitendialog und Fotoansicht besitzen ebenfalls einen Sichtschutz. Nach erneuter Aktivierung verlangt die eingeschaltete Sperre eine Authentifizierung; ein laufender Authentifizierungsdialog löst keine Endlosschleife aus. Die Funktion benötigt noch eine praktische Prüfung auf dem iPhone.

### Export und Löschung

CSV enthält Tageswerte und fünf zusätzliche Umfangsspalten am tatsächlichen Messtag, mit Semikolontrennung, Dezimalkomma und UTF-8-BOM. JSON-Schema 2 enthält Tagesdaten, Mahlzeitenmetadaten mit Bildreferenzen und wöchentliche `bodyMeasurements`. Beide Exporte werden nur auf aktive Anforderung erzeugt und sind **unverschlüsselt**. Sie enthalten keine Fotodateien und keine Einstellungen; ein vollständiger ZIP-/Passwort-Backup-Export und ein Import sind nicht implementiert.

Das Teilen-Menü öffnet sich erst nach der Exportaktion. Wählt der Nutzer dort einen Cloud-Anbieter, gibt er diese Daten selbst weiter. Exportdateien werden nach Schließen des Teilen-Menüs beziehungsweise beim nächsten App-Start entfernt. Kopien in anderen Apps kann Daily Balance nicht löschen.

„Alle Daten löschen“ verlangt eine Bestätigung, löscht Tagesdaten, Mahlzeiten und Einstellungen, entfernt Fotos, Vorschaubilder, Exportdateien sowie lokale Erinnerungen. Bereits weitergegebene Daten und ursprüngliche Mediathekfotos werden dadurch nicht gelöscht. Die Löschung ist eine logische Datenbank-/Dateilöschung; es wird keine forensische Secure-Erase-Garantie gegeben.

## Tests und Build-Prüfung

Der aktuelle Nachweis und Links zu echten Simulator-Screenshots stehen in [Documentation/VALIDATION.md](VALIDATION.md).

- **Xcode-Builds für Simulator und iPhone erfolgreich, ohne Signierung.** `build-for-testing` baut zusätzlich beide Test-Targets.
- **31 Kernlogiktests im Simulator ausgeführt, 0 Fehler.** Datumsgrenzen, Sommerzeit, Zeitzonen, Erinnerungsfälle, optionale Werte, Validierung und getrennte Diagrammwerte.
- **Simulator-Prüfstand vom 16. Oktober 2026, einschließlich gezielter Wiederholungen: 56 unterschiedliche Tests bestanden, 0 verbleibende Fehler, 1 Test übersprungen.** Ausgeführt wurden 31 Kernlogiktests, 18 iOS-Integrationstests und 7 UI-Tests. Zusätzlich geprüft wurden wöchentliche Körpermaße, ISO-Wochenwechsel, Migration vom ursprünglichen Schema und Zentimeter-Exporte. Bestätigt wurden Datenbankneustart, Fotoablage, GPS-Entfernung, Backup-Ausschluss, Löschen, Navigation, Kalenderwechsel, Abbrechen und App-Neustart. Ein einzelner Gewichtspunkt ist mit Datumsachse sichtbar und lässt sich antippen, um Datum und Wert anzuzeigen.
- **Der zusätzliche Dateischutztest für echte Hardware wird im Simulator ausdrücklich übersprungen.** Der Simulator liefert für das iOS-Dateischutzattribut keinen Wert. Damit wird keine erfolgreiche Prüfung der Hardwareverschlüsselung behauptet.
- App-Code und Tests wurden zusätzlich direkt gegen das iOS-SDK kompiliert; der App-Code wurde erfolgreich gelinkt.

In Xcode nach Auswahl eines Simulators **⌘U** ausführen. UI-Tests verwenden in Debug-Builds ein eigenes Verzeichnis pro Testsession und berühren das normale Tagebuch nicht. Der Neustarttest verwendet innerhalb seiner Session denselben Store. Keine Test-Spezialpfade sind in Release-Builds aktiv.

Kernlogiktests ohne Simulator, aus diesem Projektverzeichnis:

```sh
python3 Scripts/run_core_tests.py
```

Alternativ bei korrekt eingerichtetem vollständigem Xcode:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test
```

Compiler- und Linkerprüfung ohne App-Start:

```sh
python3 Scripts/check_swift.py
```

Xcode-Build für den Simulator, ohne Start und ohne Code-Signing:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project DailyBalance.xcodeproj -scheme DailyBalance \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/DailyBalanceBuild CODE_SIGNING_ALLOWED=NO build
```

Mit `build-for-testing` anstelle von `build` werden auch die Test-Targets gebaut. Für einen echten Testlauf später in Xcode ein vorhandenes Simulatorgerät auswählen. `run_core_tests.py` und `check_swift.py` nutzen temporäre Build-Verzeichnisse und ändern weder `xcode-select` noch das eigene Tagebuch. Das Compilerflag `-disable-sandbox` bezieht sich auf verschachtelte Compiler-Plugin-Prozesse in dieser eingeschränkten Umgebung; die normalen Xcode-Projekteinstellungen benötigen es nicht.

## Noch praktisch zu prüfen

- Kamera, verweigerte Kamerarechte und Fotoauswahl auf dem echten iPhone.
- Tatsächliche Benachrichtigungszustellung einschließlich Fokus, Tageswechsel, Neustart und Zeitzonenwechsel.
- Layout bei maximalem Dynamic Type, VoiceOver, Hell-/Dunkelmodus und langen Notizen.
- Face ID, Gerätecode, Abbruch und Sperre bei offenen Bearbeitungsfenstern.
- Verhalten unter knappem Speicher und mit mehreren Jahren realer Fotodaten.
- Wiederherstellungsverhalten und Backup-Ausschluss auf einem echten Gerät.

Optionale Erweiterungen wie Injektionstagebuch, gleitende Durchschnitte, medizinische Interpretationen, ein frei wählbarer Diagrammzeitraum und vollständige verschlüsselte Sicherungsarchive gehören nicht zu dieser Version.

## Weiterentwicklung

Die App-Quellen können direkt bearbeitet werden. Falls das Xcode-Projekt neu generiert werden soll: `python3 Scripts/generate_project.py`. Der Generator besitzt keine externen Abhängigkeiten und erstellt stabile Objektkennungen. Das Icon ist eine reproduzierbare CoreGraphics-Zeichnung; `Scripts/make_icon.swift` erzeugt das mitgelieferte PNG. App-Name, Bundle-ID und Texte lassen sich im Projekt beziehungsweise den Swift-Dateien ändern.

Die Erweiterung um die unabhängige Körpermaße-Entität ist durch einen Upgrade-Test vom ursprünglichen Schema abgedeckt. Bei weiteren Schemaänderungen die Migrationsstrategie und Wiederherstellungstests fortführen, bevor persönliche Daten mit einer neuen Version geöffnet werden.
