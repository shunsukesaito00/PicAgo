import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    var isDestructive: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PicAgoTypography.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, PicAgoSpacing.md)
            .background(
                (isDestructive ? Color.red.opacity(0.85) : PicAgoColor.accent)
                    .opacity(configuration.isPressed ? 0.85 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PicAgoTypography.headline)
            .foregroundStyle(PicAgoColor.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, PicAgoSpacing.md)
            .background(PicAgoColor.subtleFill)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

struct YearChoiceButton: View {
    let year: Int
    let state: YearChoiceState
    let action: () -> Void

    enum YearChoiceState {
        case idle
        case selectedCorrect
        case selectedWrong
        case disabled
    }

    var body: some View {
        Button(action: action) {
            Text(verbatim: "\(year)")
                .font(PicAgoTypography.yearChoice)
                .foregroundStyle(foreground)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, minHeight: 56)
                .padding(.vertical, PicAgoSpacing.xs)
                .background(background)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(border, lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
        .disabled(state != .idle)
        .accessibilityLabel(Text(String(localized: "a11y.year_choice \(year)")))
    }

    private var foreground: Color {
        switch state {
        case .idle: return PicAgoColor.choiceInk
        case .disabled: return PicAgoColor.choiceInkMuted
        case .selectedCorrect, .selectedWrong: return .white
        }
    }

    private var background: Color {
        switch state {
        case .idle: return PicAgoColor.choiceFill
        case .selectedCorrect: return PicAgoColor.success
        case .selectedWrong: return PicAgoColor.accent
        case .disabled: return PicAgoColor.choiceFillMuted
        }
    }

    private var border: Color {
        switch state {
        case .idle: return Color.black.opacity(0.06)
        case .selectedCorrect: return PicAgoColor.success
        case .selectedWrong: return PicAgoColor.accent
        case .disabled: return Color.white.opacity(0.12)
        }
    }
}

struct BrandMark: View {
    var size: BrandSize = .regular

    enum BrandSize {
        case hero, regular, compact

        var font: Font {
            switch self {
            case .hero: return .system(size: 44, weight: .bold, design: .default)
            case .regular: return .system(size: 28, weight: .bold, design: .default)
            case .compact: return .system(size: 20, weight: .bold, design: .default)
            }
        }
    }

    var body: some View {
        Text("PicAgo")
            .font(size.font)
            .foregroundStyle(PicAgoColor.accent)
            .accessibilityAddTraits(.isHeader)
    }
}

struct SoftAtmosphereBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let light = [
            Color(red: 0.98, green: 0.95, blue: 0.92),
            Color(red: 0.96, green: 0.93, blue: 0.90),
            Color(red: 0.94, green: 0.88, blue: 0.84)
        ]
        let dark = [
            Color(red: 0.10, green: 0.09, blue: 0.08),
            Color(red: 0.14, green: 0.11, blue: 0.10),
            Color(red: 0.18, green: 0.12, blue: 0.10)
        ]
        LinearGradient(
            colors: colorScheme == .dark ? dark : light,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .overlay(
            RadialGradient(
                colors: [PicAgoColor.accent.opacity(colorScheme == .dark ? 0.18 : 0.12), .clear],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 420
            )
            .ignoresSafeArea()
        )
    }
}
