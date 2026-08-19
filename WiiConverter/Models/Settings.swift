import Foundation
import Combine

enum ExistingFileBehavior: String, CaseIterable, Codable { case overwrite = "Überschreiben", skip = "Überspringen", ask = "Fragen" }
enum RegionDisplay: String, CaseIterable, Codable { case all = "Alle anzeigen", pal = "Nur PAL", ntsc = "Nur NTSC", hidden = "Ausblenden" }
enum LogVerbosity: String, CaseIterable, Codable { case minimal = "Minimal", normal = "Normal", detailed = "Detailliert" }

/// Reines Datenmodell (Codable, kein SwiftUI/Combine-Kram) — wird 1:1 nach
/// JSON gespiegelt und in AppSettings (ObservableObject) gehalten.
struct SettingsData: Codable, Equatable {
    var outputFolder: String = (NSHomeDirectory() as NSString).appendingPathComponent("WiiConverter/output")
    var verifyAfterConvert: Bool = true
    var trimISO: Bool = false
    var existingFileBehavior: ExistingFileBehavior = .ask
    var deleteOriginalAfterConvert: Bool = true
    var parallelJobs: Int = 2

    var autoRenameGameTDB: Bool = true
    var fetchCoverArt: Bool = true
    var regionDisplay: RegionDisplay = .all

    var smbEnabled: Bool = false
    var smbHost: String = ""
    var smbShare: String = ""
    var smbUser: String = ""
    var smbPass: String = ""

    var telegramEnabled: Bool = false
    var telegramToken: String = ""
    var telegramChatID: String = ""
    var logVerbosity: LogVerbosity = .normal
}

/// ObservableObject-Wrapper für SwiftUI-Bindings, speichert bei jeder
/// Änderung (debounced) automatisch in UserDefaults.
final class AppSettings: ObservableObject {
    @Published var data: SettingsData

    private static let key = "WiiConverter.settings"
    private var bag = Set<AnyCancellable>()

    init() {
        if let stored = UserDefaults.standard.data(forKey: Self.key),
           let decoded = try? JSONDecoder().decode(SettingsData.self, from: stored) {
            data = decoded
        } else {
            data = SettingsData()
        }

        $data
            .dropFirst()
            .debounce(for: .milliseconds(400), scheduler: RunLoop.main)
            .sink { [weak self] newValue in
                guard let self else { return }
                if let encoded = try? JSONEncoder().encode(newValue) {
                    UserDefaults.standard.set(encoded, forKey: Self.key)
                }
            }
            .store(in: &bag)
    }

    func saveNow() {
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: Self.key)
        }
    }
}
