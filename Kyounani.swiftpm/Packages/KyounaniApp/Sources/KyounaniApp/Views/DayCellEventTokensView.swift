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
                EventTokenRenderer(event: occurrence.baseEvent, occurrenceDate: occurrence.occurrenceDate)
            }
            if summary.remainingCount > 0 {
                Text("+\(summary.remainingCount)")
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#endif
