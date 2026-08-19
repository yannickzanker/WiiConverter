import SwiftUI

@main
struct WiiConverterApp: App {
    @StateObject private var settings: AppSettings
    @StateObject private var converter: Converter

    init() {
        let s = AppSettings()
        let c = Converter(settings: s)
        _settings = StateObject(wrappedValue: s)
        _converter = StateObject(wrappedValue: c)
    }

    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView()
                .environmentObject(settings)
                .environmentObject(converter)
                .preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)

        // Erzeugt automatisch den "Einstellungen…"-Eintrag im App-Menü
        // (Cmd+,) — eigenständiges Fenster über die Menüleiste.
        Settings {
            SettingsView(settings: settings)
                .preferredColorScheme(.dark)
                .onDisappear { converter.updateSettings(settings) }
        }

        // Menüleisten-Icon, wie WLAN/Batterie/Wetter: schlichtes Symbol im
        // Ruhezustand, Fortschritts-Ring während der Konvertierung. Klick
        // öffnet ein Popover mit Status + Kurzbefehlen.
        MenuBarExtra {
            MenuBarPopoverContent(converter: converter)
        } label: {
            MenuBarProgressLabel(converter: converter)
        }
        .menuBarExtraStyle(.window)
    }
}
