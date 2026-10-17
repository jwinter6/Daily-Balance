# Das Projekt zu GitHub hochladen

Der entpackte Ordner `DailyBalance-GitHub` ist die spätere Repository-Wurzel. Darin liegen `README.md`, `.gitignore`, `DailyBalance.xcodeproj` und der App-Quellcode direkt nebeneinander.

## Mit Git veröffentlichen

1. Auf GitHub ein neues, leeres Repository erstellen. Keine zusätzliche README, `.gitignore` oder Lizenz automatisch anlegen lassen, damit der erste Push eine leere Historie vorfindet.
2. Im Terminal in den entpackten Projektordner wechseln. Den Beispielpfad ersetzen:

   ```sh
   cd "/Pfad/zu/DailyBalance-GitHub"
   ```

3. Das lokale Repository initialisieren und die vorbereiteten Dateien übernehmen:

   ```sh
   git init -b main
   git add .
   git status --short
   git commit -m "Initial commit: Daily Balance 1.2"
   ```

4. Die HTTPS-Adresse des eigenen GitHub-Repositorys einsetzen und hochladen:

   ```sh
   git remote add origin https://github.com/DEIN-NAME/DEIN-REPOSITORY.git
   git push -u origin main
   ```

Die Anmeldung erfolgt über die eigene Git-Konfiguration beziehungsweise den angebotenen Anmeldedialog. Zugangsdaten nicht in Dateien oder die Remote-URL schreiben. Dieses Exportpaket enthält weder eine Git-Historie noch eine voreingestellte Remote-Adresse.

## Was versioniert wird

Quellcode, Xcode-Projekt, gemeinsames Scheme, Tests, Werkzeuge, App-Icon, Bild-Assets, Datenschutzmanifest und Dokumentation gehören ins Repository. Die Dokumentations-Screenshots zeigen künstliche Testwerte.

Die `.gitignore` lässt diese Dateien ausdrücklich zu. Insbesondere sind JSON, PNG, `Package.swift`, `Package.resolved`, `project.pbxproj` und `xcshareddata` nicht pauschal ausgeschlossen.

## Was lokal bleibt

- Persönliche Xcode-Zustände in `xcuserdata` und `*.xcuserstate`.
- Build-Verzeichnisse, Test-Ergebnisbundles, Archive, installierbare Builds und Protokolle.
- Signierzertifikate, private Schlüssel, Provisionierungsprofile und lokale Zugangsdaten.
- App-Datenbanken sowie persönliche Foto-, Export- und Sicherungsverzeichnisse, wenn sie in die Repository-Wurzel kopiert werden.
- `.DS_Store`, Python-Caches und lokale Swift-Package-Arbeitsverzeichnisse.

Die App speichert ihre Daten normalerweise im eigenen iOS-App-Verzeichnis, nicht im Repository. Für manuelle Kopien persönlicher Dateien die vorgesehenen lokalen Ordner `Photos`, `Exports` oder `Backups` verwenden. Eigene persönliche Screenshots nicht zu den öffentlichen Test-Screenshots legen.

Git ignoriert neue Dateien entsprechend diesen Regeln. Bereits eingecheckte Dateien werden durch eine spätere `.gitignore` nicht aus der Historie entfernt. Vor jedem Commit mit `git status --short` den tatsächlichen Inhalt prüfen.

## Hinweise zum Export

Der App-Code entspricht Version 1.2 (3). Für diesen Export wurden ausschließlich Repository-Dokumentation und Ignore-Regeln angepasst. Rohe Testprotokolle, lokale Simulator-Kennungen, maschinenspezifische Ergebnisdateien und der Prüfsummenstand des bisherigen Downloadpakets wurden nicht übernommen. Der historische Prüfbericht bleibt als Text erhalten; er ist kein neuer Testlauf dieses Exports.

Eine Lizenzdatei wurde nicht vorgegeben oder automatisch ergänzt.
