# WiiConverter (SwiftUI, macOS)

Native macOS-App, ISO → WBFS, mit Einstellungen-Fenster im Hover-Sidebar-Pattern.

## Setup in Xcode

1. Xcode öffnen → **File → New → Project → macOS → App**
   - Product Name: `WiiConverter`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - **Wichtig:** Deployment Target auf **macOS 13 (Ventura)** oder neuer setzen —
     `MenuBarExtra` gibt es erst ab macOS 13.
2. Das neu erzeugte `ContentView.swift` und `WiiConverterApp.swift` im Projekt löschen (Referenz entfernen).
3. Alle Dateien aus diesem Ordner (`WiiConverter/`) per Drag & Drop ins Xcode-Projekt ziehen
   (Ordnerstruktur `Models/` und `Views/` beibehalten, "Copy items if needed" aktivieren).
4. Backend installieren (auf dem Mac, im Terminal):
   ```bash
   brew install wit
   ```
5. Bauen & starten (⌘R).

## Backend

Die App ruft `wit` (Wiimms ISO Tools) direkt per `Process` auf und sucht es unter
`/opt/homebrew/bin`, `/usr/local/bin` oder `/usr/bin`. Falls `wit` woanders liegt,
in `Converter.swift` → `findExecutable()` den Pfad ergänzen.

## Wichtiger Hinweis zur Verlässlichkeit

Dieser Code wurde **nicht in Xcode kompiliert oder getestet** — die Sandbox hier
läuft unter Linux ohne Swift-Toolchain/macOS-SDK, ein echter Build-Check war
technisch nicht möglich. Die Syntax ist sorgfältig geschrieben, aber realistisch
können beim ersten Build in Xcode kleinere Fehler auftauchen (z. B. API-Details
bei `Menu`/`NSOpenPanel` je nach macOS-Version, oder Swift-Versions-Eigenheiten
bei `async/await` in Combine-Kontexten). Schick mir die Fehlermeldung aus Xcode,
dann fixe ich gezielt.

## Menüleiste & Fortschritts-Icon

- **Einstellungen** öffnen sich über das App-Menü (**WiiConverter → Einstellungen…**)
  bzw. **⌘,** — Standard-macOS-Verhalten dank SwiftUIs `Settings`-Scene.
- Ein **Icon in der Menüleiste oben rechts** (neben WLAN/Batterie/Wetter) zeigt
  den Status: im Ruhezustand ein schlichtes Scheiben-Symbol, während einer
  Konvertierung ein Fortschritts-Ring, der sich live füllt — genau wie das
  Batterie-Icon zwischen "voll" und "lädt". Klick darauf öffnet ein Popover
  (wie bei WLAN/Batterie) mit großem Ring, Status, letzter Log-Zeile und
  Kurzbefehlen: Fenster öffnen, Einstellungen, Beenden.
- Umgesetzt mit SwiftUIs `MenuBarExtra` (`.menuBarExtraStyle(.window)`) —
  das native macOS-API dafür, kein eigenes Panel/Fenster-Gebastel nötig.

## Was die Einstellungen bewirken

- **Konvertierung**: Ausgabeordner, Verifizieren nach Konvertierung, Trimmen,
  Verhalten bei existierender Datei, Original-ISO löschen, parallele Jobs
- **Spiel-Metadaten**: Auto-Umbenennen via GameTDB, Cover-Art laden, Region-Anzeige
- **Ausgabe/Ziel**: SMB-Ausgabe (Server, Freigabe, Zugangsdaten)
- **Benachrichtigungen**: Telegram bei Fertigstellung, Log-Ausführlichkeit

Alle Einstellungen werden automatisch (debounced) in `UserDefaults` gespeichert.
