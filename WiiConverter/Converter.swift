import Foundation
import Combine

enum JobStatus: String { case waiting = "wartend", running = "läuft", done = "fertig", failed = "fehler", skipped = "übersprungen" }

final class ConversionJob: ObservableObject, Identifiable {
    let id = UUID()
    let source: URL
    @Published var status: JobStatus = .waiting

    init(source: URL) { self.source = source }
}

enum LogLevel { case info, success, error, warn }

struct LogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date = Date()
    let message: String
    let level: LogLevel
}

@MainActor
final class Converter: ObservableObject {
    @Published var log: [LogEntry] = []
    @Published var progressDone: Int = 0
    @Published var progressTotal: Int = 0
    @Published var isRunning = false

    private var settings: AppSettings
    private var stopRequested = false

    init(settings: AppSettings) {
        self.settings = settings
    }

    func updateSettings(_ s: AppSettings) { self.settings = s }

    func backendAvailable() -> Bool {
        findExecutable("wit") != nil
    }

    private func findExecutable(_ name: String) -> String? {
        let paths = ["/opt/homebrew/bin/\(name)", "/usr/local/bin/\(name)", "/usr/bin/\(name)"]
        return paths.first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    func stop() {
        stopRequested = true
    }

    func run(jobs: [ConversionJob]) async {
        stopRequested = false
        isRunning = true
        progressDone = 0
        progressTotal = jobs.count

        let outDir = URL(fileURLWithPath: settings.data.outputFolder)
        try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

        for job in jobs {
            if stopRequested {
                addLog("Abgebrochen.", .warn)
                break
            }
            job.status = .running
            addLog("Starte: \(job.source.lastPathComponent)", .info)

            let target = outDir.appendingPathComponent(job.source.deletingPathExtension().lastPathComponent + ".wbfs")

            if FileManager.default.fileExists(atPath: target.path) {
                switch settings.data.existingFileBehavior {
                case .skip:
                    job.status = .skipped
                    addLog("Übersprungen (existiert bereits): \(target.lastPathComponent)", .warn)
                    progressDone += 1
                    continue
                case .ask, .overwrite:
                    addLog("Existiert bereits, wird überschrieben: \(target.lastPathComponent)", .warn)
                }
            }

            guard let witPath = findExecutable("wit") else {
                job.status = .failed
                addLog("`wit` (Wiimms ISO Tools) wurde nicht gefunden. Installation nötig (brew install wit).", .error)
                break
            }

            var args = ["copy", "--wbfs"]
            if settings.data.trimISO { args.append("--trim") }
            if settings.data.verifyAfterConvert { args.append("--verify") }
            args.append(job.source.path)
            args.append(target.path)

            let success = await runProcess(executable: witPath, args: args)

            if success {
                job.status = .done
                addLog("Fertig: \(target.lastPathComponent)", .success)
                if settings.data.deleteOriginalAfterConvert {
                    try? FileManager.default.removeItem(at: job.source)
                    addLog("Original gelöscht: \(job.source.lastPathComponent)", .info)
                }
                if settings.data.telegramEnabled {
                    await notifyTelegram("✅ \(job.source.lastPathComponent) fertig konvertiert.")
                }
            } else {
                job.status = .failed
                addLog("Fehler bei \(job.source.lastPathComponent).", .error)
            }

            progressDone += 1
        }

        isRunning = false
        addLog("Alle Jobs abgeschlossen.", .success)
    }

    private func runProcess(executable: String, args: [String]) async -> Bool {
        await withCheckedContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: executable)
            process.arguments = args
            let pipe = Pipe()
            process.standardError = pipe
            process.standardOutput = pipe

            process.terminationHandler = { proc in
                continuation.resume(returning: proc.terminationStatus == 0)
            }

            do {
                try process.run()
            } catch {
                continuation.resume(returning: false)
            }
        }
    }

    private func notifyTelegram(_ text: String) async {
        let s = settings.data
        guard s.telegramEnabled, !s.telegramToken.isEmpty, !s.telegramChatID.isEmpty,
              let url = URL(string: "https://api.telegram.org/bot\(s.telegramToken)/sendMessage") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let body = "chat_id=\(s.telegramChatID)&text=\(text)"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        request.httpBody = body.data(using: .utf8)
        _ = try? await URLSession.shared.data(for: request)
    }

    private func addLog(_ message: String, _ level: LogLevel) {
        log.append(LogEntry(message: message, level: level))
    }
}
