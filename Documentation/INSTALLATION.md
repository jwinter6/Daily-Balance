# Daily Balance auf deinem iPhone installieren

Diese Anleitung bezieht sich auf die hier verwendete Xcode-Version 27.1. Die englischen Bezeichnungen stehen so in Xcode. Bei älteren Versionen kann „Apple Accounts“ nur „Accounts“ und „Device Hub“ noch „Devices and Simulators“ heißen.

## 1. Das Projekt öffnen

1. Falls du die ZIP verwendest: die Projekt-ZIP im Finder doppelt anklicken und entpacken.
2. Im entpackten Projektordner die Datei **DailyBalance.xcodeproj** doppelt anklicken. Damit öffnest du das gesamte Projekt in Xcode.
3. Falls Xcode erforderliche Komponenten anbietet, diese installieren. Die Xcode-Version muss die iOS-Version deines iPhone unterstützen.
4. Mit **⌘1** die linke Projektübersicht anzeigen, falls sie ausgeblendet ist.

## 2. Deinen Apple-Account in Xcode anmelden

Das Signing-Team verknüpft deine App mit deinem Entwicklerkonto. Für die Installation auf deinem eigenen iPhone genügt grundsätzlich ein kostenloser Apple-Account; Xcode nennt dessen Team **Personal Team**. Ein kostenpflichtiges Developer-Abo ist dafür nicht zwingend nötig. [Apple: Developer account overview](https://developer.apple.com/help/account/basics/about-your-developer-account).

1. Oben in der macOS-Menüleiste **Xcode → Settings…** öffnen, alternativ **⌘,** drücken.
2. In den Einstellungen **Apple Accounts** auswählen.
3. Auf **+** beziehungsweise **Add Apple Account…** klicken.
4. Mit deinem Apple-Account anmelden und gegebenenfalls die Zwei-Faktor-Anmeldung abschließen. Zugangsdaten ausschließlich in Apples Anmeldedialog eingeben.
5. Warten, bis der Account mit seinem Team angezeigt wird. Bei einem kostenlosen Konto steht gewöhnlich dein Name mit **(Personal Team)**.
6. Das Einstellungsfenster schließen.

Die Anmeldung unter Apple Accounts und die Zuweisung des Teams im Projekt sind getrennte Schritte. [Apple: App auf Geräten ausführen](https://developer.apple.com/documentation/xcode/running-your-app-on-simulated-or-physical-devices).

## 3. Das Signing-Team im Projekt auswählen

1. Links im Projektnavigator ganz oben auf das **blaue Projektsymbol DailyBalance** klicken.
2. Im jetzt geöffneten Projekteditor gibt es eine weitere Liste mit den Bereichen **PROJECT** und **TARGETS**. Unter **TARGETS** den Eintrag **DailyBalance** auswählen.
3. Oben im Editor auf **Signing & Capabilities** klicken. Falls nötig den Bereich **Signing** aufklappen.
4. Das Häkchen **Automatically manage signing** setzen beziehungsweise gesetzt lassen.
5. Im Auswahlfeld **Team** deinen Namen beziehungsweise **Dein Name (Personal Team)** auswählen. Wenn du bereits Mitglied eines passenden Entwicklerteams bist, kannst du dieses auswählen.
6. Unter **Bundle Identifier** steht zunächst `de.jan.dailybalance`. Wenn Xcode meldet, dass die Kennung nicht verfügbar ist, eine eigene eindeutige Kennung eintragen, beispielsweise `de.jan.meintagebuch2026.dailybalance`, und mit **Return** bestätigen. Die Beispielkennung muss bei Apple noch verfügbar sein.
7. Xcode die Erstellung der Signatur und des Entwicklungsprofils abschließen lassen. Falls noch ein Gerät benötigt wird, zunächst mit Schritt 4 fortfahren; das ist beim ersten Einrichten normal.

So sieht die Zuordnung aus:

```text
Projektübersicht links: DailyBalance (blaues Projektsymbol)
    → Projekteditor: TARGETS
        → DailyBalance
            → Signing & Capabilities
                → Automatically manage signing ✓
                → Team: Dein Name (Personal Team)
```

Wähle für diesen Schritt das **App-Target DailyBalance**. Wenn du später Tests direkt auf dem iPhone ausführen möchtest und Xcode für `DailyBalanceTests` oder `DailyBalanceUITests` nach einem Team fragt, dort dasselbe Team einstellen. Bei einer geänderten App-Kennung die Test-Kennungen passend ergänzen, zum Beispiel `.tests` und `.uitests`.

Referenzen: [Apple: Team zuweisen](https://developer.apple.com/documentation/xcode/preparing-your-app-for-distribution), [Apple: Bundle Identifier ändern](https://developer.apple.com/documentation/xcode/changing-the-bundle-identifier).

## 4. Das iPhone mit dem Mac verbinden

1. Dein iPhone mit einem **datenfähigen USB-Kabel** an den Mac anschließen.
2. Das iPhone entsperren. Bei „Diesem Computer vertrauen?“ auf **Vertrauen** tippen und den Gerätecode eingeben. Falls der Mac den Anschluss bestätigen lässt, auch dort erlauben.
3. Zurück in Xcode oben neben dem App-/Scheme-Namen die Geräteauswahl öffnen. Über **Manage Devices…** gelangst du zur Geräteverwaltung. In aktuellen Xcode-Versionen ist diese auch über **Xcode → Open Developer Tool → Device Hub** erreichbar.
4. Dein physisches iPhone auswählen beziehungsweise die angebotene Kopplung abschließen. Warten, bis die Vorbereitung beendet ist. Währenddessen das iPhone entsperrt und verbunden lassen.
5. Falls Xcode **Developer Mode Required** meldet: Am iPhone **Einstellungen → Datenschutz & Sicherheit → Entwicklermodus** einschalten, den angeforderten Neustart durchführen und danach die Aktivierung samt Gerätecode bestätigen.
6. Falls „Entwicklermodus“ noch fehlt, zuerst die Kopplung in Xcode beginnen. Der Schalter wird laut Apple erst nach begonnener oder früherer Kopplung angezeigt.

Referenzen: [Apple: Geräte und Run Destination](https://developer.apple.com/documentation/xcode/running-your-app-on-simulated-or-physical-devices), [Apple: Entwicklermodus](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device).

## 5. Dein echtes iPhone als Ziel auswählen

1. In der oberen Xcode-Symbolleiste das **Scheme DailyBalance** auswählen.
2. Direkt daneben auf den aktuellen Gerätenamen klicken. Dort steht möglicherweise noch **iPhone 18 Pro** aus der Simulatorauswahl oder **Any iOS Device**.
3. In der Liste unter den **physischen/verbundenen Geräten** dein eigenes iPhone auswählen. Es kann beispielsweise **Mein iPhone** heißen, abhängig vom Gerätenamen in deinen iOS-Einstellungen.
4. Achte auf den konkreten verbundenen Gerätenamen: Ein Eintrag unter **iOS Simulators** bezeichnet weiterhin einen Simulator; ein generisches **Any iOS Device** ist ebenfalls noch kein ausgewähltes einzelnes iPhone.
5. Jetzt auf das Dreieck **▶ Run** oben links klicken oder **⌘R** drücken.
6. Xcode baut, signiert, installiert und startet Daily Balance. Bei der ersten Installation können weitere Systembestätigungen erscheinen.

Die Kombination oben lautet dann sinngemäß:

```text
▶   DailyBalance   ›   Mein iPhone
```

Das Team wählst du **im Projekteditor**; dein iPhone wählst du **oben in der Symbolleiste**. [Apple: Scheme und Run Destination](https://developer.apple.com/documentation/xcode/running-your-app-on-simulated-or-physical-devices).

## 6. Nach der Installation

Wenn iOS einen nicht vertrauten Entwickler meldet, unter **Einstellungen → Allgemein → VPN & Geräteverwaltung** das eigene Entwicklerprofil öffnen und vertrauen, sofern dieser Eintrag und die Aufforderung vorhanden sind. Dann die App erneut starten. [Apple: Beispiel für Personal-Team-Installation](https://developer.apple.com/documentation/appclip/fruta-building-a-feature-rich-app-with-swiftui).

Nach erfolgreichem Start kannst du das Kabel abziehen. Die App läuft lokal auf dem iPhone und benötigt den Mac für den täglichen Gebrauch nicht.

Bei einem kostenlosen **Personal Team** laufen die Entwicklungsprofile nach **7 Tagen** ab. Danach musst du die App wieder aus Xcode bauen und installieren. Verwende dabei weiterhin dieselbe Bundle-ID und lösche die bestehende App nicht; eine normale Aktualisierung ist für den Erhalt der Daten vorgesehen. Die App-Daten sind von regulären Backups ausgeschlossen und dürfen nicht durch eine Deinstallation verloren gehen. [Apple: Personal-Team-Beschränkungen](https://developer.apple.com/help/account/basics/about-your-developer-account).

## Falls etwas nicht klappt

| Meldung oder Beobachtung | Nächster Schritt |
|---|---|
| „Signing … requires a development team“ | App-Target DailyBalance → Signing & Capabilities → Team auswählen |
| Team ist leer | Xcode → Settings → Apple Accounts → Account anmelden; danach erneut die Team-Liste öffnen |
| Bundle Identifier ist nicht verfügbar | Im App-Target eine andere eindeutige Kennung eintragen |
| „No profiles … found“ | Automatische Signierung prüfen, echtes iPhone verbinden und als Run Destination wählen; falls angeboten „Try Again“/„Register Device“ verwenden |
| iPhone erscheint nicht | Kabel mit Datenübertragung, entsperrtes iPhone und Vertrauensabfrage prüfen; in Manage Devices/Device Hub den Gerätestatus lesen |
| „Developer Mode Required“ | Entwicklermodus am iPhone aktivieren, Neustart und anschließende Bestätigung abschließen |
| Gerät oder iOS wird nicht unterstützt | Xcode beziehungsweise die benötigten Plattformkomponenten passend zur iOS-Version aktualisieren |
| Schlüsselbund fragt nach Zugriff für `codesign` | Wenn der Dialog tatsächlich vom gerade gestarteten Xcode-Build kommt, den Zugriff auf den eigenen Entwicklungsschlüssel bestätigen; gefragt ist gegebenenfalls das Mac-Anmeldepasswort |

Die Signierung kann eine Verbindung zu Apples Entwicklerdiensten benötigen. Die installierte Tagebuch-App selbst besitzt kein Backend und funktioniert offline.
