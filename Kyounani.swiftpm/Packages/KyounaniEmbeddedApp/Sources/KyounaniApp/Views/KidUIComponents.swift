#if canImport(SwiftUI)
import SwiftUI

public struct KidSectionIsland<Content: View>: View {
    @Environment(\.kyounaniTheme) private var theme
    private let title: String
    private let tint: Color
    private let content: Content
    private let onTitleTap: (() -> Void)?

    public init(title: String, tint: Color, onTitleTap: (() -> Void)? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.tint = tint
        self.onTitleTap = onTitleTap
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.itemGap) {
            HStack {
                Text(title)
                    .font(theme.fonts.islandTitle)
                    .foregroundStyle(theme.colors.primaryText)
                    .onTapGesture { onTitleTap?() }
                Spacer()
                Circle()
                    .fill(tint)
                    .frame(width: 12, height: 12)
            }
            content
        }
        .padding(theme.spacing.cardPadding)
        .background(
            LinearGradient(colors: [tint.opacity(0.22), theme.colors.tabBackground.opacity(0.84)], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .cardStyle(background: .clear)
    }
}

public struct KidSoftBackground: View {
    @Environment(\.kyounaniTheme) private var theme

    public init() {}

    public var body: some View {
        LinearGradient(
            colors: [theme.colors.pageBackgroundTop, theme.colors.pageBackgroundBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}
#endif
