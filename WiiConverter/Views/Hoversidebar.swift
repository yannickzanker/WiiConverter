import SwiftUI

struct SidebarItem: Identifiable, Equatable {
    let id: String
    let icon: String        // SF Symbol
    let label: String
    let section: String
}

/// Schmale Icon-Spalte links (60px), klappt beim Hovern als Overlay auf
/// 250px auf (Inhalt daneben bewegt sich nicht — Overlay via .zIndex/.offset,
/// nicht Teil des Layout-Flows). Pin-Button hält sie offen.
struct HoverSidebar: View {
    let sections: [String]
    let items: [SidebarItem]
    @Binding var selection: String

    @State private var expanded = false
    @State private var pinned = false
    @State private var hoveredID: String? = nil
    @State private var collapseWorkItem: DispatchWorkItem? = nil

    private var currentWidth: CGFloat {
        (expanded || pinned) ? DS.sidebarExpandedWidth : DS.sidebarCollapsedWidth
    }
    private var progress: CGFloat {
        let w = currentWidth
        return (w - DS.sidebarCollapsedWidth) / (DS.sidebarExpandedWidth - DS.sidebarCollapsedWidth)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Pin-Button
            HStack {
                Button {
                    pinned.toggle()
                    if pinned { withAnimation(.easeOut(duration: DS.sidebarAnimDuration)) { expanded = true } }
                } label: {
                    Image(systemName: pinned ? "pin.fill" : "pin")
                        .font(.system(size: 12))
                        .foregroundColor(pinned ? DS.accent : DS.textSecondary)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .padding(.leading, 16)
                Spacer()
            }
            .padding(.top, 10)
            .padding(.bottom, 6)

            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(sections, id: \.self) { section in
                        if currentWidth > DS.sidebarCollapsedWidth + 20 {
                            SectionLabel(text: section)
                                .padding(.leading, 18)
                                .padding(.top, 10)
                                .padding(.bottom, 4)
                                .opacity(Double(progress))
                        } else {
                            RowSeparator().padding(.horizontal, 14).padding(.vertical, 4)
                        }
                        ForEach(items.filter { $0.section == section }) { item in
                            sidebarRow(item)
                        }
                    }
                }
                .padding(.horizontal, 6)
            }
        }
        .frame(width: currentWidth, alignment: .leading)
        .background(DS.panelBG)
        .shadow(color: Color.black.opacity(0.35 * Double(progress)), radius: 16, x: 6, y: 0)
        .animation(.easeOut(duration: DS.sidebarAnimDuration), value: currentWidth)
        .onHover { hovering in
            collapseWorkItem?.cancel()
            if hovering {
                withAnimation(.easeOut(duration: DS.sidebarAnimDuration)) { expanded = true }
            } else if !pinned {
                let work = DispatchWorkItem {
                    withAnimation(.easeOut(duration: DS.sidebarAnimDuration)) { expanded = false }
                }
                collapseWorkItem = work
                DispatchQueue.main.asyncAfter(deadline: .now() + DS.sidebarCollapseDelay, execute: work)
            }
        }
        .zIndex(10) // Overlay über dem Inhalt, kein Reflow
    }

    @ViewBuilder
    private func sidebarRow(_ item: SidebarItem) -> some View {
        let isActive = selection == item.id
        let isHovered = hoveredID == item.id

        Button {
            selection = item.id
        } label: {
            HStack(spacing: 0) {
                Image(systemName: item.icon)
                    .font(.system(size: 15))
                    .foregroundColor(isActive ? DS.textPrimary : DS.textSecondary)
                    .frame(width: 24, alignment: .center)
                    .padding(.leading, 18 - 12) // Icon fix bei ~18px vom Rand

                if currentWidth > DS.sidebarCollapsedWidth + 20 {
                    Text(item.label)
                        .font(.system(size: 12))
                        .foregroundColor(isActive ? DS.textPrimary : DS.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .opacity(Double(progress))
                        .padding(.leading, 8)
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .frame(height: 36)
            .background(
                RoundedRectangle(cornerRadius: DS.radiusChip, style: .continuous)
                    .fill(isActive ? DS.accentAlpha(0.2) : (isHovered ? DS.hoverFill : .clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: DS.radiusChip, style: .continuous)
                    .stroke(isActive ? DS.accent : .clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { h in hoveredID = h ? item.id : nil }
        .padding(.vertical, 1)
    }
}
