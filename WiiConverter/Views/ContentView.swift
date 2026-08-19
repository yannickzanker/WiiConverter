import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var converter: Converter
    @State private var jobs: [ConversionJob] = []

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 0) {
                header
                HStack(alignment: .top, spacing: 16) {
                    queueCard
                    logCard
                }
                .padding(20)
                footer
            }
        }
        .frame(minWidth: 760, minHeight: 560)
    }

    // MARK: Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("WiiConverter")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(DS.textPrimary)
                Text("ISO → WBFS")
                    .font(.system(size: 12))
                    .foregroundColor(DS.textSecondary)
            }
            Spacer()
            Text("Einstellungen: ⌘,")
                .font(.system(size: 11))
                .foregroundColor(DS.textMuted)
            Button("+ ISOs hinzufügen") { addFiles() }
                .buttonStyle(SecondaryButtonStyle())
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    // MARK: Warteschlange

    private var queueCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: "Warteschlange")
            ScrollView {
                VStack(spacing: 4) {
                    if jobs.isEmpty {
                        Text("Noch keine ISOs hinzugefügt.")
                            .font(.system(size: 12))
                            .foregroundColor(DS.textMuted)
                            .padding(.top, 20)
                    }
                    ForEach(jobs) { job in
                        jobRow(job)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DS.panelBG)
        .clipShape(RoundedRectangle(cornerRadius: DS.radiusPanel))
        .overlay(RoundedRectangle(cornerRadius: DS.radiusPanel).stroke(DS.border, lineWidth: 1))
    }

    private func jobRow(_ job: ConversionJob) -> some View {
        HStack {
            Text(job.source.lastPathComponent)
                .font(.system(size: 12))
                .foregroundColor(DS.textPrimary)
                .lineLimit(1)
            Spacer()
            Text(job.status.rawValue)
                .font(.system(size: 11))
                .foregroundColor(statusColor(job.status))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(DS.inputBG)
        .clipShape(RoundedRectangle(cornerRadius: DS.radiusChip))
    }

    private func statusColor(_ s: JobStatus) -> Color {
        switch s {
        case .waiting: return DS.textMuted
        case .running: return DS.accent
        case .done: return DS.success
        case .failed: return DS.error
        case .skipped: return DS.warning
        }
    }

    // MARK: Protokoll

    private var logCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: "Protokoll")
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(converter.log) { entry in
                            HStack(alignment: .top, spacing: 6) {
                                Text(timeString(entry.timestamp))
                                    .font(DS.mono(11))
                                    .foregroundColor(DS.textMuted)
                                Text(entry.message)
                                    .font(DS.mono(11))
                                    .foregroundColor(logColor(entry.level))
                            }
                            .id(entry.id)
                        }
                    }
                }
                .onChange(of: converter.log.count) { _, _ in
                    if let last = converter.log.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DS.panelBG)
        .clipShape(RoundedRectangle(cornerRadius: DS.radiusPanel))
        .overlay(RoundedRectangle(cornerRadius: DS.radiusPanel).stroke(DS.border, lineWidth: 1))
    }

    private func logColor(_ level: LogLevel) -> Color {
        switch level {
        case .info: return DS.textSecondary
        case .success: return DS.success
        case .error: return DS.error
        case .warn: return DS.warning
        }
    }

    private func timeString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f.string(from: date)
    }

    // MARK: Footer

    private var footer: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                ProgressView(value: converter.progressTotal > 0 ? Double(converter.progressDone) / Double(converter.progressTotal) : 0)
                    .tint(DS.accent)
                    .frame(width: 320)
                Text(converter.progressTotal > 0
                     ? "\(converter.progressDone)/\(converter.progressTotal) konvertiert"
                     : "Bereit. Das Fortschritts-Widget erscheint oben am Bildschirm, sobald es losgeht.")
                    .font(.system(size: 11))
                    .foregroundColor(DS.textSecondary)
            }
            Spacer()
            Button(converter.isRunning ? "Läuft…" : "Konvertierung starten") {
                startConversion()
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(converter.isRunning)
        }
        .padding(16)
        .background(DS.panelBG)
        .overlay(Rectangle().frame(height: 1).foregroundColor(DS.border), alignment: .top)
    }

    // MARK: Aktionen

    private func addFiles() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [UTType(filenameExtension: "iso") ?? .data]
        if panel.runModal() == .OK {
            for url in panel.urls {
                jobs.append(ConversionJob(source: url))
            }
        }
    }

    private func startConversion() {
        guard !jobs.isEmpty else { return }
        guard converter.backendAvailable() else {
            let alert = NSAlert()
            alert.messageText = "Wiimms ISO Tools nicht gefunden"
            alert.informativeText = "Installiere `wit` z. B. via: brew install wit\noder https://wit.wiimm.de"
            alert.runModal()
            return
        }
        let pending = jobs.filter { $0.status == .waiting }
        Task {
            await converter.run(jobs: pending)
        }
    }
}
