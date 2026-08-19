import SwiftUI

// MARK: - Karte / Panel

struct Card<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 0) { content }
            .padding(16)
            .background(DS.panelBG)
            .clipShape(RoundedRectangle(cornerRadius: DS.radiusPanel, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DS.radiusPanel, style: .continuous)
                    .stroke(DS.border, lineWidth: 1)
            )
    }
}

// MARK: - Sektionstitel

struct SectionLabel: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(DS.sectionTitle())
            .tracking(0.8) // ~108% Letterspacing-Annäherung
            .foregroundColor(DS.textMuted)
    }
}

// MARK: - Buttons

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(DS.bgBottom) // dunkler Text auf Orange, wegen Kontrast
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(configuration.isPressed ? DS.accentPressed : DS.accent)
            .clipShape(RoundedRectangle(cornerRadius: DS.radiusControl, style: .continuous))
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    @State private var hovering = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13))
            .foregroundColor(DS.textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(configuration.isPressed ? DS.hoverFill : DS.panelBG)
            .clipShape(RoundedRectangle(cornerRadius: DS.radiusControl, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DS.radiusControl, style: .continuous)
                    .stroke(hovering ? DS.accent : DS.border, lineWidth: 1)
            )
            .onHover { h in
                withAnimation(.easeOut(duration: 0.12)) { hovering = h }
            }
    }
}

// MARK: - Toggle-Zeile

struct ToggleRow: View {
    let title: String
    var description: String? = nil
    @Binding var isOn: Bool

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(DS.textPrimary)
                if let description {
                    Text(description)
                        .font(.system(size: 11))
                        .foregroundColor(DS.textSecondary)
                }
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .toggleStyle(AccentToggleStyle())
                .labelsHidden()
        }
    }
}

struct AccentToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        RoundedRectangle(cornerRadius: 11)
            .fill(configuration.isOn ? DS.accent : DS.border)
            .frame(width: 38, height: 22)
            .overlay(
                Circle()
                    .fill(DS.textPrimary)
                    .frame(width: 18, height: 18)
                    .offset(x: configuration.isOn ? 8 : -8)
                    .animation(.easeOut(duration: 0.15), value: configuration.isOn)
            )
            .onTapGesture { configuration.isOn.toggle() }
    }
}

// MARK: - Dropdown-Zeile

struct DropdownRow: View {
    let title: String
    var description: String? = nil
    @Binding var selection: String
    let options: [String]

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(DS.textPrimary)
                if let description {
                    Text(description)
                        .font(.system(size: 11))
                        .foregroundColor(DS.textSecondary)
                }
            }
            Spacer()
            Menu {
                ForEach(options, id: \.self) { opt in
                    Button(opt) { selection = opt }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(selection)
                        .font(.system(size: 12))
                        .foregroundColor(DS.textPrimary)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9))
                        .foregroundColor(DS.textSecondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(DS.inputBG)
                .clipShape(RoundedRectangle(cornerRadius: DS.radiusControl, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: DS.radiusControl, style: .continuous)
                        .stroke(DS.border, lineWidth: 1)
                )
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
    }
}

// MARK: - Textfeld-Zeile

struct TextFieldRow: View {
    let title: String
    @Binding var text: String
    var secure: Bool = false
    var placeholder: String = ""

    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(DS.textSecondary)
            Group {
                if secure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .textFieldStyle(.plain)
            .font(.system(size: 12))
            .foregroundColor(DS.textPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(DS.inputBG)
            .clipShape(RoundedRectangle(cornerRadius: DS.radiusControl, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DS.radiusControl, style: .continuous)
                    .stroke(focused ? DS.accent : DS.border, lineWidth: 1)
            )
            .focused($focused)
            .animation(.easeOut(duration: 0.12), value: focused)
        }
    }
}

// MARK: - Stepper-Zeile (Zahl-Option mit +/- statt Freitext)

struct StepperRow: View {
    let title: String
    var description: String? = nil
    @Binding var value: Int
    var range: ClosedRange<Int> = 1...6

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(DS.textPrimary)
                if let description {
                    Text(description)
                        .font(.system(size: 11))
                        .foregroundColor(DS.textSecondary)
                }
            }
            Spacer()
            HStack(spacing: 0) {
                Button { if value > range.lowerBound { value -= 1 } } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(DS.textSecondary)
                        .frame(width: 26, height: 26)
                }
                .buttonStyle(.plain)

                Text("\(value)")
                    .font(.system(size: 13))
                    .foregroundColor(DS.textPrimary)
                    .frame(width: 26)

                Button { if value < range.upperBound { value += 1 } } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(DS.textSecondary)
                        .frame(width: 26, height: 26)
                }
                .buttonStyle(.plain)
            }
            .padding(2)
            .background(DS.inputBG)
            .clipShape(RoundedRectangle(cornerRadius: DS.radiusControl, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DS.radiusControl, style: .continuous)
                    .stroke(DS.border, lineWidth: 1)
            )
        }
    }
}

// MARK: - Trennlinie

struct RowSeparator: View {
    var body: some View {
        Rectangle()
            .fill(DS.border)
            .frame(height: 1)
            .padding(.vertical, 10)
    }
}
