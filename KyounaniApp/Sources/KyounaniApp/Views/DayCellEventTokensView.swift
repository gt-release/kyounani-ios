#if canImport(SwiftUI)
import SwiftUI

public struct DayCellEventTokensView: View {
    let summary: DayEventSummary

    public init(summary: DayEventSummary) {
        self.summary = summary
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(summary.topOccurrences, id: \.id) { occurrence in
                renderEventToken(event: occurrence.baseEvent)
            }
            if summary.remainingCount > 0 {
                Text("+\(summary.remainingCount)")
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func renderEventToken(event: Event) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color.green.opacity(0.2))
                .frame(width: 16, height: 16)
                .overlay(
                    Text(String(event.title.prefix(1)))
                        .font(.caption2.bold())
                        .foregroundStyle(.green)
                )
            Text(event.title)
                .font(.caption2)
                .lineLimit(1)
        }
    }
}

#endif
