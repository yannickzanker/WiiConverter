import SwiftUI
import AppKit

struct SettingsView: View {
    @ObservedObject var settings: AppSettings

    @State private var selection = "konvertierung"

    /// Schließt das Einstellungen-Fenster (eigenständiges Fenster über die
    /// Menüleiste/Cmd+,, kein Sheet mehr — daher kein Environment .dismiss).
    private func closeWindow() {
        NSApp.keyWindow?.close()
    }

    private let sections = ["Allgemein", "Netzwerk", "Sonstiges"]
    private let items: [SidebarItem] = [
        SidebarItem(id: "konvertierung", icon: "gearshape", label: "Konvertierung", section: "Allgemein"),
        SidebarItem(id: "metadaten", icon: "tag", label: "Spiel-Metadaten", section: "Allgemein"),
        SidebarItem(id: "ausgabe", icon: "externaldrive.connected.to.line.below", label: "Ausgabe / Ziel", section: "Netzwerk"),
        SidebarItem(id: "sonstiges", icon: "bell", label: "Benachrichtigungen", section: "Sonstiges"),
    ]

    var body: some View {
        ZStack(alignment: .topLeading) {
            AppBackground()

            HStack(spacing: 0) {
                // Platzhalter, damit der Inhalt nicht unter der eingeklappten
                // Sidebar liegt — die Sidebar selbst liegt als Overlay darüber.
                Color.clear.frame(width: DS.sidebarCollapsedWidth)

                VStack(spacing: 0) {
                    ScrollView {
                        Group {
                            switch selection {
                            case "konvertierung": konvertierungPanel
                            case "metadaten": metadatenPanel
                            case "ausgabe": ausgabePanel
                            default: sonstigesPanel
                            }
                        }
                        .padding(20)
                    }

                    Divider().background(DS.border)

                    HStack {
                        Spacer()
                        Button("Abbrechen") { closeWindow() }
                            .buttonStyle(SecondaryButtonStyle())
                        Button("Fertig") { settings.saveNow(); closeWindow() }
                            .buttonStyle(PrimaryButtonStyle())
                    }
                    .padding(16)
                    .background(DS.panelBG)
                }
            }

            HoverSidebar(sections: sections, items: items, selection: $selection)
        }
        .frame(width: 760, height: 560)
    }

    // MARK: Panels

    private var konvertierungPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Konvertierung").font(.system(size: 18, weight: .bold)).foregroundColor(DS.textPrimary)

            Card {
                Text("Standard-Ausgabeordner").font(.system(size: 13)).foregroundColor(DS.textPrimary)
                HStack {
                    TextField("", text: $settings.data.outputFolder)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                        .foregroundColor(DS.textPrimary)
                        .padding(.horizontal, 10).padding(.vertical, 7)
                        .background(DS.inputBG)
                        .clipShape(RoundedRectangle(cornerRadius: DS.radiusControl))
                        .overlay(RoundedRectangle(cornerRadius: DS.radiusControl).stroke(DS.border, lineWidth: 1))
                    Button("Wählen…") { pickFolder() }
                        .buttonStyle(SecondaryButtonStyle())
                }
                .padding(.top, 6)
            }

            Card {
                ToggleRow(title: "Nach Konvertierung verifizieren",
                          description: "Prüft die WBFS-Datei per Checksumme, dauert etwas länger.",
                          isOn: $settings.data.verifyAfterConvert)
                RowSeparator()
                ToggleRow(title: "ISO trimmen",
                          description: "Reduziert die Dateigröße durch Entfernen ungenutzter Bereiche.",
                          isOn: $settings.data.trimISO)
                RowSeparator()
                ToggleRow(title: "Original-ISO danach löschen",
                          description: "⚠ Löscht die Quell-ISO nach erfolgreicher Konvertierung endgültig.",
                          isOn: $settings.data.deleteOriginalAfterConvert)
            }

            Card {
                DropdownRow(title: "Bei existierender Datei",
                            description: "Verhalten, falls die WBFS-Datei bereits existiert.",
                            selection: Binding(
                                get: { settings.data.existingFileBehavior.rawValue },
                                set: { settings.data.existingFileBehavior = ExistingFileBehavior(rawValue: $0) ?? .ask }
                            ),
                            options: ExistingFileBehavior.allCases.map(\.rawValue))
                RowSeparator()
                StepperRow(title: "Parallele Konvertierungen",
                           description: "Anzahl gleichzeitiger Konvertierungs-Jobs.",
                           value: $settings.data.parallelJobs, range: 1...6)
            }
        }
    }

    private var metadatenPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Spiel-Metadaten").font(.system(size: 18, weight: .bold)).foregroundColor(DS.textPrimary)

            Card {
                ToggleRow(title: "Automatisch umbenennen (GameTDB)",
                          description: "Ersetzt die Game-ID durch den echten Spieltitel aus der GameTDB-Datenbank.",
                          isOn: $settings.data.autoRenameGameTDB)
                RowSeparator()
                ToggleRow(title: "Cover-Art automatisch laden",
                          description: "Lädt das Cover-Bild passend zur Game-ID von GameTDB.",
                          isOn: $settings.data.fetchCoverArt)
            }

            Card {
                DropdownRow(title: "Region-Anzeige",
                            description: "Wie Regions-Infos (PAL/NTSC) in der Liste dargestellt werden.",
                            selection: Binding(
                                get: { settings.data.regionDisplay.rawValue },
                                set: { settings.data.regionDisplay = RegionDisplay(rawValue: $0) ?? .all }
                            ),
                            options: RegionDisplay.allCases.map(\.rawValue))
            }
        }
    }

    private var ausgabePanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ausgabe / Ziel").font(.system(size: 18, weight: .bold)).foregroundColor(DS.textPrimary)

            Card {
                ToggleRow(title: "SMB-Ausgabe aktivieren",
                          description: "Konvertierte Spiele direkt auf einen Netzwerkpfad (z. B. NAS) schreiben.",
                          isOn: $settings.data.smbEnabled)
            }

            Card {
                VStack(alignment: .leading, spacing: 10) {
                    TextFieldRow(title: "Server / IP", text: $settings.data.smbHost, placeholder: "192.168.178.92")
                    TextFieldRow(title: "Freigabename", text: $settings.data.smbShare, placeholder: "NAS/wii-games")
                    TextFieldRow(title: "Benutzername", text: $settings.data.smbUser)
                    TextFieldRow(title: "Passwort", text: $settings.data.smbPass, secure: true)
                }
            }
        }
    }

    private var sonstigesPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Benachrichtigungen & Log").font(.system(size: 18, weight: .bold)).foregroundColor(DS.textPrimary)

            Card {
                ToggleRow(title: "Telegram-Benachrichtigung",
                          description: "Sendet eine Nachricht, sobald eine Konvertierung fertig ist.",
                          isOn: $settings.data.telegramEnabled)
            }

            Card {
                VStack(alignment: .leading, spacing: 10) {
                    TextFieldRow(title: "Bot-Token (von @BotFather)", text: $settings.data.telegramToken, secure: true)
                    TextFieldRow(title: "Chat-ID (von @userinfobot)", text: $settings.data.telegramChatID)
                }
            }

            Card {
                DropdownRow(title: "Log-Ausführlichkeit",
                            description: "Wie detailliert der Konvertierungs-Log geschrieben wird.",
                            selection: Binding(
                                get: { settings.data.logVerbosity.rawValue },
                                set: { settings.data.logVerbosity = LogVerbosity(rawValue: $0) ?? .normal }
                            ),
                            options: LogVerbosity.allCases.map(\.rawValue))
            }
        }
    }

    private func pickFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            settings.data.outputFolder = url.path
        }
    }
}
