# Prüfstand · 16. Oktober 2026

Daily Balance wurde im **iPhone-18-Pro-Simulator mit iOS 27.0** gestartet und getestet. Über den Hauptlauf und gezielte Wiederholungen wurden **57 unterschiedliche Tests geprüft: 56 bestanden, 1 hardwareabhängiger Test übersprungen, 0 verbleibende Fehler**. Gezählt wird jeweils das letzte Ergebnis eines Testfalls.

Diese Seite hält den Prüfstand vom 16. Oktober 2026 fest. Rohe Testprotokolle und maschinenspezifische Ergebnisdateien sind nicht Teil des GitHub-Exports. Die ausführliche Signing- und Installationsanleitung steht in [INSTALLATION.md](INSTALLATION.md).

| Prüfung | Ergebnis |
|---|---|
| Werkzeugkette | Xcode 27.1, Swift 6.4, Deployment iOS 17.0, SDK iOS 27.1 |
| Simulatorlauf | iPhone 18 Pro, arm64, iOS 27.0 |
| Kernlogik | 31 Tests unter iOS bestanden |
| iOS-Persistenz und Bilder | 18 Tests bestanden, einschließlich Datenbank-Upgrade und Körpermaßen |
| Hardwaregestützter iOS-Dateischutz | 1 eigener Test im Simulator übersprungen; physisches iPhone erforderlich |
| UI-Tests | 7 Tests bestanden, einschließlich Körpermaßen, Kalender und Diagrammen |
| Simulator-App und Test-Targets | Erfolgreich gebaut und ausgeführt |
| Generischer iPhone-Build | `BUILD SUCCEEDED`, ohne Code-Signing |
| Projekt/Plists/Assets | Statische Prüfung bestanden; 24 App-Quelldateien referenziert; Icon 1.024 × 1.024 Pixel, RGB ohne Alpha |
| Netzwerk-/Cloud-Quellcodeprüfung | Keine Netzwerkclients, CloudKit ausdrücklich deaktiviert, keine Cloud-/HealthKit-Entitlements |
| Physisches iPhone, Signing und Installation | Noch nicht ausgeführt; eigenes Team muss in Xcode gewählt werden |
| Kamera, Face ID und tatsächliche Erinnerungszustellung | Noch auf dem echten iPhone zu prüfen |
| System-Backups | Backup-Ausschlussattribut im Simulator geprüft; keine iCloud-/Finder-Sicherung und Wiederherstellung durchgeführt |

## Neu in Version 1.2: Wasser und abgeschlossene Tage

Separate Wasser-Erinnerungen mit vier Intervallen und eigenem Tageszeitraum. Geprüft wurden lokale, täglich wiederholende Kalender-Trigger, das gemeinsame Anfragelimit, fortbestehende Wasserzeiten nach einem Check-in, das Entfernen beim Ausschalten und das Übernehmen alter Einstellungen ohne Wasserfelder. Der UI-Test aktiviert Wasser, wählt „Alle 2 Stunden“, startet die App neu und prüft den erhaltenen Zustand sowie das unabhängige Ausschalten.

Vergangene Tageswerte und Mahlzeiten können weder überschrieben, verschoben noch einzeln gelöscht werden. Auch eine am Vortag gespeicherte Wochenmessung lässt sich nicht unter dem heutigen Datum ersetzen. Die Sperre greift im Speicherdienst und nach einem simulierten Tageswechsel bei geöffnetem Store. Der Verlauf-UI-Test öffnet einen künstlichen gestrigen Eintrag und prüft die gesperrten Aktionen; heute bleibt bearbeitbar. Das App-Logo ersetzt das bisherige Symbol, die beiden gewünschten Sätze wurden entfernt.

Anleitung: [WASSER-UND-VERLAUF.md](WASSER-UND-VERLAUF.md).

## Seit Version 1.1: wöchentliche Körpermaße

Fünf optionale Umfänge in Zentimetern, genau ein Datensatz je ISO-Woche von Montag bis Sonntag. Der Upgrade-Test vom alten Datenbankschema erhält Gewicht, Mahlzeitenfotos und Einstellungen. Wochenmessungen lassen sich seit Version 1.2 nur an ihrem Messtag korrigieren und werden in JSON und CSV am tatsächlichen Messtag exportiert. Der neue UI-Test gibt alle fünf Werte ein, startet die App neu und prüft die sichtbaren Werte und das interaktive Zentimeter-Diagramm.

Anleitung: [KOERPERMASSE.md](KOERPERMASSE.md).

## Was tatsächlich geprüft wurde

**Kernlogik:** Drei Erinnerungen ohne Eintrag, erster Eintrag vor/nach den Erinnerungszeiten, Löschen des einzigen Eintrags, zukünftige dokumentierte Tage, leere Entwürfe, einzelne Bewertungen, Notizen, Mahlzeit allein, Zeitänderungen, Sommerzeit, Zeitzonen, Jahresgrenzen, deutsche Dezimalzahlen, Wertevalidierung und Diagrammwerte ohne künstliche Nullen.

**Persistenz und Fotos:** Tageswerte nach erneutem Öffnen des SwiftData-Containers, Aktualisierung desselben Tages ohne zweite Tageszeile, leere/gelöschte Tageswerte, lokale Originale und Vorschaubilder, GPS-Entfernung aus einer tatsächlich mit GPS-Daten versehenen Bilddatei, Fototausch mit Bereinigung, chronologische Mahlzeiten, fehlerhafter Fotoimport, persistente Einstellungen, zurückgelesener Backup-Ausschluss, vollständige logische Datenlöschung und Text-Export.

**Bedienung:** Erststart ohne Mitteilungen, Wechsel zwischen allen vier Tabs, vorheriger/nächster Kalendermonat, Gewicht mit Dezimalkomma speichern und nach Prozessneustart wieder anzeigen, Eingabe abbrechen ohne Speicherung, Bewertung mit einem Tippen speichern und nach Neustart wieder anzeigen sowie Gewichtsdiagramm öffnen. Der Diagrammtest tippt einen einzelnen Messpunkt an und prüft die sichtbare Detailanzeige mit Jahr und tatsächlichem Gewicht.

Die Tests für die Erinnerungslogik verwenden den reinen Planner, die tatsächlich erzeugten `UNNotificationRequest`-/Kalender-Trigger-Objekte und einen ersetzbaren Benachrichtigungsdienst. Sie bestätigen die Planung und Dokumentationszustände, **nicht** die tatsächliche zeitgesteuerte Zustellung eines iOS-Mitteilungsbanners.

## Ablauf und Wiederholungen

Der Hauptlauf prüfte alle 57 Tests. Ein neuer Wasser-UI-Test tippte zunächst auf die umgebende SwiftUI-Zeile statt auf deren nativen Schalter und meldete dadurch einen Fehler. Nach der Korrektur der Testbedienung bestand der gezielte Wiederholungslauf einschließlich Aktivieren, Intervallauswahl, App-Neustart und Ausschalten. Der um eine bei geöffnetem Store wechselnde Uhr ergänzte Tagesschutztest wurde ebenfalls gezielt wiederholt und bestanden. Die Zusammenfassung zählt Testfälle nach ihrem jeweils letzten Ergebnis, nicht mehrfach nach der Zahl der Ausführungen. Der ursprüngliche Hauptlauf enthielt diesen inzwischen behobenen Testbedienungsfehler. Die hier genannten Zahlen berücksichtigen das letzte Ergebnis je Testfall.

## Im Test korrigiert

Bei nur einem Messpunkt bot Swift Charts zunächst keine brauchbare Datumsachse. Die Skala umfasst jetzt einen Tag vor und nach diesem Messpunkt; es werden dabei keine zusätzlichen Messwerte erzeugt. Zusätzlich verwendet das Diagramm eine ausdrückliche Tippgeste, damit Datum und Wert nach dem Antippen sichtbar bleiben. Der entsprechende UI-Test wurde ergänzt.

Der Simulator liefert beim Lesen von `.protectionKey` keinen Hardware-Dateischutzwert. Die ursprüngliche kombinierte Assertion wurde deshalb in zwei fachlich getrennte Prüfungen aufgeteilt: Einstellungen und Backup-Ausschluss werden im Simulator getestet; `testHardwareFileProtectionIsComplete` überspringt sich dort mit einer ausdrücklichen Begründung und prüft auf einem physischen iPhone weiterhin `NSFileProtectionComplete`.

## Screenshots der laufenden App

Die folgenden Bilder stammen aus den automatisierten UI-Tests, nicht aus Design-Mockups. **94,6 kg und sämtliche dargestellten Körpermaße sind künstliche Testwerte.** Die UI-Tests verwenden eigene Verzeichnisse pro Testsession.

- [Heute mit gespeichertem Testgewicht](Screenshots/Heute.png)
- [Gewichtsdiagramm mit ausgewähltem Messpunkt](Screenshots/Gewichtsdiagramm.png)
- [Ernährungskalender](Screenshots/Kalender.png)
- [Einstellungen mit App-Logo](Screenshots/Einstellungen.png)
- [Separate Wasser-Erinnerungen](Screenshots/Wasser-Erinnerungen.png)
- [Vergangener Tag: nur ansehen](Screenshots/Vergangener-Tag.png)
- [Körpermaße: Wochenübersicht](Screenshots/Koerpermasse-Uebersicht.png)
- [Körpermaße: Zentimeter-Diagramm](Screenshots/Koerpermasse-Verlauf.png)

Die acht Ansichten wurden im Hellmodus visuell geprüft. Maximaler Dynamic Type, vollständige VoiceOver-Bedienung und Dunkelmodus bleiben zusätzliche praktische Prüfungen.

## Tests wiederholen

Aus dem Projektverzeichnis:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project DailyBalance.xcodeproj -scheme DailyBalance \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' \
  -derivedDataPath /tmp/daily-balance-xcode-build \
  -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO ARCHS=arm64 test
```

Den Simulatornamen im Befehl durch ein lokal verfügbares Gerät ersetzen. Alternativ in Xcode einen Simulator auswählen und mit **⌘U** testen.

Für einen iPhone-Build ohne Signierung:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project DailyBalance.xcodeproj -scheme DailyBalance \
  -sdk iphoneos -destination 'generic/platform=iOS' \
  -derivedDataPath /tmp/daily-balance-device-build \
  CODE_SIGNING_ALLOWED=NO build
```

Der erfolgreiche generische Geräte-Build bestätigt keine signierte Installation. Dafür das eigene Signing-Team und das physische iPhone gemäß [INSTALLATION.md](INSTALLATION.md) auswählen.
