#if canImport(SwiftUI)
import SwiftUI

public struct DayDetailView: View {
    @EnvironmentObject private var appVM: AppViewModel
    @ObservedObject var calendarVM: CalendarViewModel
    @ObservedObject var speechService: SpeechService

    let date: Date
    @State private var selectedOccurrence: EventOccurrence?

    public init(date: Date, calendarVM: CalendarViewModel, speechService: SpeechService) {
        self.date = date
        self.calendarVM = calendarVM
        self.speechService = speechService
    }

    public var body: some View {
        let occurrences = calendarVM.dayOccurrences(on: date, childFilter: appVM.filter, includeDraft: appVM.parentModeUnlocked)

        Group {
            if occurrences.isEmpty {
                Text("この日の予定はありません")
                    .foregroundStyle(.secondary)
            } else {
                List(occurrences, id: \.id) { occurrence in
                    Button {
                        speechService.speak(occurrence.baseEvent.title)
                        selectedOccurrence = occurrence
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(occurrence.baseEvent.title)
                                .font(.headline)
                            Text(timeText(occurrence.displayStart, allDay: occurrence.baseEvent.isAllDay))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle(titleText)
        .sheet(item: $selectedOccurrence) { occ in
            TimerRingView(targetDate: occ.displayStart)
                .padding()
        }
    }

    private var titleText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M/d(E)"
        return formatter.string(from: date)
    }

    private func timeText(_ date: Date, allDay: Bool) -> String {
        if allDay { return "終日" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

#endif
