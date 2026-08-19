import SwiftUI

/// Zentrale Design-Tokens — exakt wie vorgegeben, keine Abweichungen,
/// keine erfundenen zusätzlichen Farben. Weitere Grautöne werden nur im
/// gleichen warmen Schwarz-Bereich wie panelBG/border abgeleitet.
enum DS {

    // MARK: Farben

    static let bgTop = Color(hex: 0x161311)
    static let bgBottom = Color(hex: 0x0a0908)
    static let panelBG = Color(hex: 0x121110)
    static let border = Color(hex: 0x2c2723)

    static let accent = Color(hex: 0xff8a1e)
    static let accentHover = Color(hex: 0xffa64d)
    static let accentPressed = Color(hex: 0xe26f0a)

    static let success = Color(hex: 0x34d399)
    static let error = Color(hex: 0xf87171)
    static let warning = Color(hex: 0xfbbf24)

    static let textPrimary = Color(hex: 0xf5f1ea)
    static let textSecondary = Color(hex: 0xb3aca3)
    static let textMuted = Color(hex: 0x736c63)

    /// Eingabefelder: dunkler als Karten-Hintergrund
    static let inputBG = Color(hex: 0x181512)
    /// Abgeleiteter, etwas hellerer Ton für Hover-Flächen (gleicher warmer Bereich wie border)
    static let hoverFill = Color(hex: 0x1c1815)

    static func accentAlpha(_ a: Double) -> Color {
        accent.opacity(a)
    }

    // MARK: Radien

    static let radiusPanel: CGFloat = 14
    static let radiusControl: CGFloat = 8
    static let radiusChip: CGFloat = 7

    // MARK: Typografie

    static let fontFamily = "Segoe UI" // Fällt auf Systemfont zurück, falls nicht installiert
    static let monoFamily = "Cascadia Code"

    static func body(_ size: CGFloat = 11 * 1.333) -> Font {
        .custom(fontFamily, size: size)
    }

    static func sectionTitle() -> Font {
        .custom(fontFamily, size: 9 * 1.333).bold()
    }

    static func mono(_ size: CGFloat = 11) -> Font {
        .custom(monoFamily, size: size)
    }

    // MARK: Sidebar-Timing

    static let sidebarCollapsedWidth: CGFloat = 60
    static let sidebarExpandedWidth: CGFloat = 250
    static let sidebarAnimDuration: Double = 0.21 // 210ms
    static let sidebarCollapseDelay: Double = 0.22 // 220ms
}

extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}

/// Vertikaler Verlauf für Fensterhintergründe (BG_TOP -> BG_BOTTOM)
struct AppBackground: View {
    var body: some View {
        LinearGradient(colors: [DS.bgTop, DS.bgBottom], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
    }
}
