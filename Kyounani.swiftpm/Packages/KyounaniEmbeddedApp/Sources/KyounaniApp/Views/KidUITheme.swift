#if canImport(SwiftUI)
import SwiftUI

public enum ThemePreset: String, CaseIterable, Identifiable {
    case kid
    case highContrast

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .kid: return "Kid"
        case .highContrast: return "High Contrast"
        }
    }
}

public struct KyounaniTheme {
    public struct Spacing {
        public let screenPadding: CGFloat
        public let sectionGap: CGFloat
        public let itemGap: CGFloat
        public let cardPadding: CGFloat
        public let minTapSize: CGFloat
    }

    public struct Corner {
        public let card: CGFloat
        public let token: CGFloat
    }

    public struct Shadow {
        public let color: Color
        public let radius: CGFloat
        public let x: CGFloat
        public let y: CGFloat
    }

    public struct Fonts {
        public let sectionHeader: Font
        public let cardTitle: Font
        public let supporting: Font
        public let plusCount: Font
        public let calendarHeader: Font
        public let dayTitle: Font
        public let tokenTitle: Font
    }

    public struct Colors {
        public let todayCard: Color
        public let nextCard: Color
        public let peekCard: Color
        public let emptyCard: Color
        public let primaryText: Color
        public let secondaryText: Color
        public let accent: Color
        public let tokenPlaceholderFill: Color
        public let tokenPlaceholderText: Color

        public let weekdayText: Color
        public let weekendText: Color
        public let holidayText: Color
        public let selectedText: Color
        public let todayText: Color

        public let weekdayBackground: Color
        public let weekendBackground: Color
        public let holidayBackground: Color
        public let selectedBackground: Color
        public let todayBackground: Color
    }

    public enum DayKind {
        case weekday
        case weekend
        case holiday
        case selected
        case today
    }

    public let spacing: Spacing
    public let corner: Corner
    public let shadow: Shadow
    public let fonts: Fonts
    public let colors: Colors
    public let stampLarge: CGFloat
    public let stampNext: CGFloat

    public static func preset(_ preset: ThemePreset) -> KyounaniTheme {
        switch preset {
        case .kid:
            return .init(
                spacing: .init(screenPadding: 20, sectionGap: 28, itemGap: 14, cardPadding: 16, minTapSize: 48),
                corner: .init(card: 18, token: 6),
                shadow: .init(color: .black.opacity(0.06), radius: 6, x: 0, y: 2),
                fonts: .init(
                    sectionHeader: .system(size: 34, weight: .heavy).lowerBoundedForKid(),
                    cardTitle: .system(size: 30, weight: .bold).lowerBoundedForKid(),
                    supporting: .system(size: 16, weight: .medium).lowerBoundedForKid(),
                    plusCount: .system(size: 30, weight: .heavy).lowerBoundedForKid(),
                    calendarHeader: .title2.bold(),
                    dayTitle: .headline,
                    tokenTitle: .caption2
                ),
                colors: .init(
                    todayCard: .green.opacity(0.16),
                    nextCard: .yellow.opacity(0.24),
                    peekCard: .blue.opacity(0.14),
                    emptyCard: .gray.opacity(0.14),
                    primaryText: .primary,
                    secondaryText: .secondary,
                    accent: .blue,
                    tokenPlaceholderFill: .green.opacity(0.2),
                    tokenPlaceholderText: .green,
                    weekdayText: .primary,
                    weekendText: .blue,
                    holidayText: .red,
                    selectedText: .white,
                    todayText: .primary,
                    weekdayBackground: .gray.opacity(0.08),
                    weekendBackground: .blue.opacity(0.08),
                    holidayBackground: .red.opacity(0.12),
                    selectedBackground: .blue.opacity(0.6),
                    todayBackground: .green.opacity(0.18)
                ),
                stampLarge: 66,
                stampNext: 72
            )
        case .highContrast:
            return .init(
                spacing: .init(screenPadding: 20, sectionGap: 28, itemGap: 14, cardPadding: 16, minTapSize: 50),
                corner: .init(card: 18, token: 6),
                shadow: .init(color: .black.opacity(0.18), radius: 0, x: 0, y: 0),
                fonts: .init(
                    sectionHeader: .system(size: 36, weight: .black).lowerBoundedForKid(),
                    cardTitle: .system(size: 32, weight: .black).lowerBoundedForKid(),
                    supporting: .system(size: 18, weight: .bold).lowerBoundedForKid(),
                    plusCount: .system(size: 32, weight: .black).lowerBoundedForKid(),
                    calendarHeader: .title2.bold(),
                    dayTitle: .headline,
                    tokenTitle: .caption.bold()
                ),
                colors: .init(
                    todayCard: .black,
                    nextCard: Color(red: 0.15, green: 0.15, blue: 0.0),
                    peekCard: Color(red: 0.0, green: 0.12, blue: 0.2),
                    emptyCard: Color(red: 0.16, green: 0.16, blue: 0.16),
                    primaryText: .white,
                    secondaryText: Color.white.opacity(0.92),
                    accent: .yellow,
                    tokenPlaceholderFill: .white,
                    tokenPlaceholderText: .black,
                    weekdayText: .white,
                    weekendText: .cyan,
                    holidayText: .red,
                    selectedText: .black,
                    todayText: .yellow,
                    weekdayBackground: Color.black.opacity(0.85),
                    weekendBackground: Color.blue.opacity(0.55),
                    holidayBackground: Color.red.opacity(0.45),
                    selectedBackground: .yellow,
                    todayBackground: Color.yellow.opacity(0.22)
                ),
                stampLarge: 66,
                stampNext: 72
            )
        }
    }

    public func dayTextColor(for kind: DayKind) -> Color {
        switch kind {
        case .weekday: return colors.weekdayText
        case .weekend: return colors.weekendText
        case .holiday: return colors.holidayText
        case .selected: return colors.selectedText
        case .today: return colors.todayText
        }
    }

    public func dayBackgroundColor(for kind: DayKind) -> Color {
        switch kind {
        case .weekday: return colors.weekdayBackground
        case .weekend: return colors.weekendBackground
        case .holiday: return colors.holidayBackground
        case .selected: return colors.selectedBackground
        case .today: return colors.todayBackground
        }
    }
}

private struct ThemeKey: EnvironmentKey {
    static let defaultValue: KyounaniTheme = .preset(.kid)
}

public extension EnvironmentValues {
    var kyounaniTheme: KyounaniTheme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

private struct ThemedCardModifier: ViewModifier {
    @Environment(\.kyounaniTheme) private var theme
    let background: Color

    func body(content: Content) -> some View {
        content
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: theme.corner.card, style: .continuous))
            .shadow(color: theme.shadow.color, radius: theme.shadow.radius, x: theme.shadow.x, y: theme.shadow.y)
    }
}

private struct MinTapTargetModifier: ViewModifier {
    @Environment(\.kyounaniTheme) private var theme

    func body(content: Content) -> some View {
        content
            .frame(minWidth: theme.spacing.minTapSize, minHeight: theme.spacing.minTapSize)
            .contentShape(Rectangle())
    }
}

public extension View {
    func cardStyle(background: Color) -> some View {
        modifier(ThemedCardModifier(background: background))
    }

    func minTapTarget() -> some View {
        modifier(MinTapTargetModifier())
    }
}

public extension Font {
    func lowerBoundedForKid() -> Font {
        self
    }
}

#endif
