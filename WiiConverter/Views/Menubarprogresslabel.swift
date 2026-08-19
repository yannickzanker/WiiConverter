import SwiftUI

/// Das eigentliche Icon in der Menüleiste (oben rechts, neben WLAN/Batterie/
/// Wetter). Im Ruhezustand ein schlichtes Scheiben-Symbol, während einer
/// Konvertierung ein Fortschritts-Ring — exakt wie das Batterie-Icon
/// zwischen "voll" und "lädt gerade" wechselt.
struct MenuBarProgressLabel: View {
    @ObservedObject var converter: Converter

    private var progress: Double {
        converter.progressTotal > 0 ? Double(converter.progressDone) / Double(converter.progressTotal) : 0
    }

    var body: some View {
        ZStack {
            if converter.isRunning {
                Circle()
                    .stroke(Color.secondary.opacity(0.35), lineWidth: 2.2)
                Circle()
                    .trim(from: 0, to: max(progress, 0.03))
                    .stroke(DS.accent, style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.25), value: progress)
            } else {
                Image(systemName: "opticaldiscdrive")
                    .font(.system(size: 13, weight: .medium))
            }
        }
        .frame(width: 18, height: 18)
    }
}
