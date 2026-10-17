# Körpermaße · einmal pro Woche

Ab Version **1.1 (2)** ergänzt Daily Balance eine freiwillige Wochenmessung in Zentimetern:

- Brustumfang
- Bauchumfang
- Po-Umfang
- Oberschenkelumfang links
- Oberschenkelumfang rechts

## Erfassen und korrigieren

Unter **Heute → Körpermaße · wöchentlich → Wochenmessung eintragen** öffnet sich die Eingabe. Jeder Wert ist einzeln optional, Dezimalkomma und Dezimalpunkt werden unterstützt. Es gibt keine vorausgefüllten Messwerte. „Speichern“ übernimmt den Entwurf; „Abbrechen“ verwirft ihn.

Pro ISO-Kalenderwoche von **Montag bis Sonntag** gibt es genau einen Eintrag. Nach dem Speichern steht auf der Übersicht **„Für diese Woche erfasst“**. Seit Version 1.2 kann diese Messung ausschließlich an ihrem tatsächlichen Messtag korrigiert oder gelöscht werden. Der Messtag ist automatisch heute und nicht frei veränderbar. An späteren Tagen derselben Woche bleibt die gespeicherte Wochenmessung sichtbar und abgeschlossen. Die nächste neue Messung ist in der folgenden Kalenderwoche möglich.

Vergangene Wochen lassen sich über den Kalender ausschließlich ansehen. Am heutigen Messtag entfernt ein leeres Feld den jeweiligen Umfang; „Wochenmessung löschen“ entfernt die fünf Maße dieser Woche. Gewicht, Bewertungen, Notizen und Mahlzeiten werden dabei nicht gelöscht.

Wenn für die gewählte Woche noch keine Messung vorliegt, kann die Karte die letzte frühere Messung als Referenz anzeigen. Deren Messtag steht ausdrücklich dabei; die Wochenanzeige bleibt dann „noch offen“.

## Visualisierung

Unter **Verlauf → Körpermaße** erscheinen fünf getrennte Diagramme. Die Zeiträume entsprechen dem bisherigen Verlauf: 7, 30, 90 Tage, 1 Jahr oder Gesamt.

Jedes Diagramm zeigt die tatsächlichen Messtage, die Werte in **cm**, Startwert, letzten Wert und Veränderung innerhalb des gewählten Zeitraums. Antippen blendet Datum und Umfang ein. Fehlende Wochen und nicht erfasste Umfänge erzeugen keine künstlichen Nullwerte. Linker und rechter Oberschenkel bleiben eigenständige Reihen; die rechte Seite verwendet einen anderen Akzent.

Die Kalender markieren den tatsächlichen Messtag. Die Liste „Alle Messwerte im Zeitraum“ enthält auch Tage, an denen ausschließlich Körpermaße erfasst wurden.

## Speicherung und Aktualisierung

Die Werte liegen in der neuen lokalen SwiftData-Entität `BodyMeasurementEntry`. Ihr eindeutiger `weekKey` verwendet das ISO-Wochenjahr, beispielsweise `2026-W01`. Der tatsächliche Messtag wird zusätzlich als `dayKey` gespeichert. So gehört auch eine Woche über den Jahreswechsel hinweg zu einem einzigen Eintrag.

Die bisherigen Entitäten `DailyEntry`, `MealEntry` und `AppSettings` wurden nicht verändert. Ein Integrationstest erstellt eine Datenbank mit dem ursprünglichen Schema, speichert Gewicht, eine Foto-Mahlzeit und Einstellungen, öffnet sie mit dem erweiterten Schema und prüft den Erhalt dieser Daten sowie das anschließende Speichern einer Wochenmessung.

Für die Installation der Aktualisierung weiterhin dieselbe Bundle-ID und dasselbe Signing-Team verwenden und die vorhandene App nicht deinstallieren.

## Erinnerungen und Export

Eine Wochenmessung zählt am eingetragenen Messtag als gültiger Tageseintrag. Die tägliche Erinnerungslogik für andere Tage arbeitet weiter wie bisher. Es werden keine zusätzlichen täglichen oder wöchentlichen Erinnerungen angelegt.

JSON-Exporte verwenden Schema-Version **2** und enthalten zusätzlich das Array `bodyMeasurements`. CSV erhält fünf zusätzliche Spalten nach den bisherigen Spalten:

```text
Brustumfang_cm
Bauchumfang_cm
Po_Umfang_cm
Oberschenkel_links_cm
Oberschenkel_rechts_cm
```

Die Werte erscheinen im CSV am tatsächlichen Messtag. Sie werden nicht auf jeden Tag derselben Woche kopiert. JSON und CSV bleiben freiwillige, unverschlüsselte lokale Text-Exporte; die Fotos sind weiterhin nicht enthalten.

Dateischutz, Backup-Ausschluss und optionale App-Sperre gelten auch für die Körpermaße. Es werden keine Daten an einen Server übertragen.
