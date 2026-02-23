#if canImport(SwiftUI)
import SwiftUI

public struct EventTokenRenderer: View {
    @EnvironmentObject private var stampStore: StampStore

    let event: Event
    let showTitle: Bool
    let iconSize: CGFloat

    public init(event: Event, showTitle: Bool = true, iconSize: CGFloat = 22) {
        self.event = event
        self.showTitle = showTitle
        self.iconSize = iconSize
    }

    public var body: some View {
        HStack(spacing: 6) {
            stampImage
                .frame(width: iconSize, height: iconSize)
                .clipShape(RoundedRectangle(cornerRadius: 6))

            if showTitle {
                Text(event.title)
                    .font(.caption2)
                    .lineLimit(1)
            }
        }
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
        RoundedRectangle(cornerRadius: 6)
            .fill(Color.green.opacity(0.2))
            .overlay(
                Text("?")
                    .font(.caption.bold())
                    .foregroundStyle(.green)
            )
    }
}

#endif
