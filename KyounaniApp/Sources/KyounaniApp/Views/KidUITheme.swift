#if canImport(SwiftUI)
import SwiftUI

public enum KidUITheme {
    public enum Spacing {
        public static let screenPadding: CGFloat = 20
        public static let sectionGap: CGFloat = 28
        public static let itemGap: CGFloat = 14
        public static let cardPadding: CGFloat = 16
    }

    public enum Size {
        public static let largeStamp: CGFloat = 66
        public static let nextCardStamp: CGFloat = 72
    }

    public enum Fonts {
        public static let sectionHeader: Font = .system(size: 34, weight: .heavy)
        public static let cardTitle: Font = .system(size: 30, weight: .bold)
        public static let supporting: Font = .system(size: 16, weight: .medium)
        public static let plusCount: Font = .system(size: 30, weight: .heavy)
        public static let calendarHeader: Font = .title2.bold()
        public static let dayTitle: Font = .headline
    }

    public enum Corner {
        public static let card: CGFloat = 18
    }

    public enum ColorPalette {
        public static let todayCard = Color.green.opacity(0.16)
        public static let nextCard = Color.yellow.opacity(0.24)
        public static let peekCard = Color.blue.opacity(0.14)
        public static let emptyCard = Color.gray.opacity(0.14)
    }
}

private struct KidCardModifier: ViewModifier {
    let background: Color

    func body(content: Content) -> some View {
        content
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: KidUITheme.Corner.card, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
    }
}

extension View {
    public func cardStyle(background: Color) -> some View {
        modifier(KidCardModifier(background: background))
    }
}

#endif
