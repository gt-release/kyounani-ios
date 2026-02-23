#if canImport(SwiftUI)
import SwiftUI

public struct EventTokenRenderer: View {
    @EnvironmentObject private var stampStore: StampStore
    @Environment(\.kyounaniTheme) private var theme

    let event: Event
    let showTitle: Bool
    let iconSize: CGFloat
    let occurrenceDate: Date?

    public init(event: Event, showTitle: Bool = true, iconSize: CGFloat = 22, occurrenceDate: Date? = nil) {
        self.event = event
        self.showTitle = showTitle
        self.iconSize = iconSize
        self.occurrenceDate = occurrenceDate
    }

    public var body: some View {
        HStack(spacing: 6) {
            stampImage
                .frame(width: iconSize, height: iconSize)
                .clipShape(RoundedRectangle(cornerRadius: theme.corner.token))

            if showTitle {
                Text(event.title)
                    .font(theme.fonts.tokenTitle)
                    .lineLimit(1)
                    .foregroundStyle(theme.colors.primaryText)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var stampImage: some View {
        let safeStampId = stampStore.ensureStampIdForDisplay(event.stampId)
        let stamp = stampStore.stamp(for: safeStampId)
        return Group {
            if let image = stampStore.image(for: stamp) {
                image
                    .resizable()
                    .scaledToFill()
            } else {
                placeholder
            }
        }
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: theme.corner.token)
            .fill(theme.colors.tokenPlaceholderFill)
            .overlay(
                Text("?")
                    .font(.caption.bold())
                    .foregroundStyle(theme.colors.tokenPlaceholderText)
            )
    }

    private var accessibilityLabel: String {
        "\(event.title)、\(datePhrase)、\(timePhrase)"
    }

    private var datePhrase: String {
        guard let occurrenceDate else { return "日付不明" }
        let calendar = Calendar(identifier: .gregorian)
        if calendar.isDateInToday(occurrenceDate) { return "きょう" }
        if calendar.isDateInTomorrow(occurrenceDate) { return "あした" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "Mがつdにち"
        return formatter.string(from: occurrenceDate)
    }

    private var timePhrase: String {
        if event.isAllDay { return "終日" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "Hじmふん"
        return formatter.string(from: occurrenceDate ?? event.startDateTime)
    }
}

#endif
