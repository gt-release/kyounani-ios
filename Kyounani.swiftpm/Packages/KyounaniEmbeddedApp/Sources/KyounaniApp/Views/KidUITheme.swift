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
        public let heroDate: Font
        public let islandTitle: Font
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
        public let pageBackgroundTop: Color
        public let pageBackgroundBottom: Color
        public let tabBackground: Color

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
                spacing: .init(screenPadding: 24, sectionGap: 22, itemGap: 14, cardPadding: 18, minTapSize: 60),
                corner: .init(card: 26, token: 8),
                shadow: .init(color: .black.opacity(0.08), radius: 18, x: 0, y: 8),
                fonts: .init(
                    sectionHeader: .system(.title2, design: .rounded).weight(.heavy),
                    cardTitle: .system(.title3, design: .rounded).weight(.bold),
                    supporting: .system(.subheadline, design: .rounded).weight(.semibold),
                    plusCount: .system(size: 32, weight: .heavy, design: .rounded),
                    calendarHeader: .system(.title2, design: .rounded).weight(.heavy),
                    dayTitle: .system(.headline, design: .rounded).weight(.bold),
                    tokenTitle: .system(.caption2, design: .rounded).weight(.bold),
                    heroDate: .system(size: 40, weight: .heavy, design: .rounded),
                    islandTitle: .system(.title3, design: .rounded).weight(.heavy)
                ),
                colors: .init(
                    todayCard: Color(red: 0.84, green: 0.94, blue: 1.0),
                    nextCard: Color(red: 1.0, green: 0.92, blue: 0.8),
                    peekCard: Color(red: 0.88, green: 0.93, blue: 0.84),
                    emptyCard: Color(red: 0.96, green: 0.96, blue: 0.98),
                    primaryText: Color(red: 0.18, green: 0.2, blue: 0.28),
                    secondaryText: Color(red: 0.39, green: 0.42, blue: 0.52),
                    accent: Color(red: 0.33, green: 0.42, blue: 1.0),
                    tokenPlaceholderFill: Color(red: 0.68, green: 0.78, blue: 1.0),
                    tokenPlaceholderText: Color(red: 0.21, green: 0.27, blue: 0.58),
                    pageBackgroundTop: Color(red: 0.97, green: 0.98, blue: 1.0),
                    pageBackgroundBottom: Color(red: 0.94, green: 0.95, blue: 0.99),
                    tabBackground: .white.opacity(0.9),
                    weekdayText: .primary,
                    weekendText: Color(red: 0.2, green: 0.38, blue: 0.9),
                    holidayText: Color(red: 0.9, green: 0.2, blue: 0.25),
                    selectedText: .white,
                    todayText: Color(red: 0.12, green: 0.2, blue: 0.5),
                    weekdayBackground: Color.white.opacity(0.9),
                    weekendBackground: Color(red: 0.87, green: 0.93, blue: 1.0),
                    holidayBackground: Color(red: 1.0, green: 0.9, blue: 0.9),
                    selectedBackground: Color(red: 0.35, green: 0.45, blue: 1.0),
                    todayBackground: Color(red: 0.75, green: 0.85, blue: 1.0)
                ),
                stampLarge: 80,
                stampNext: 88
            )
        case .highContrast:
            return .init(
                spacing: .init(screenPadding: 24, sectionGap: 22, itemGap: 14, cardPadding: 18, minTapSize: 60),
                corner: .init(card: 24, token: 8),
                shadow: .init(color: .black.opacity(0.3), radius: 0, x: 0, y: 0),
                fonts: .init(
                    sectionHeader: .system(.title2, design: .rounded).weight(.black),
                    cardTitle: .system(.title3, design: .rounded).weight(.black),
                    supporting: .system(.body, design: .rounded).weight(.bold),
                    plusCount: .system(size: 32, weight: .black, design: .rounded),
                    calendarHeader: .system(.title2, design: .rounded).weight(.black),
                    dayTitle: .system(.headline, design: .rounded).weight(.black),
                    tokenTitle: .system(.caption, design: .rounded).weight(.bold),
                    heroDate: .system(size: 42, weight: .black, design: .rounded),
                    islandTitle: .system(.title3, design: .rounded).weight(.black)
                ),
                colors: .init(
                    todayCard: .black,
                    nextCard: Color(red: 0.2, green: 0.2, blue: 0),
                    peekCard: Color(red: 0.08, green: 0.15, blue: 0.25),
                    emptyCard: Color(red: 0.16, green: 0.16, blue: 0.16),
                    primaryText: .white,
                    secondaryText: .white.opacity(0.92),
                    accent: .yellow,
                    tokenPlaceholderFill: .white,
                    tokenPlaceholderText: .black,
                    pageBackgroundTop: .black,
                    pageBackgroundBottom: Color(red: 0.08, green: 0.08, blue: 0.08),
                    tabBackground: Color(red: 0.15, green: 0.15, blue: 0.15),
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
                stampLarge: 80,
                stampNext: 88
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

#endif
