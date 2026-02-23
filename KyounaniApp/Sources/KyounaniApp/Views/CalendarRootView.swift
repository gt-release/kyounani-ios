#if canImport(SwiftUI)
import SwiftUI

public struct CalendarRootView: View {
    @State private var mode: CalendarDisplayMode = .month
    @State private var anchorDate: Date = .now
    @State private var selectedDate: Date = .now
    @State private var showDayDetail = false

    @ObservedObject var calendarVM: CalendarViewModel
    @ObservedObject var speechService: SpeechService

    public init(calendarVM: CalendarViewModel, speechService: SpeechService) {
        self.calendarVM = calendarVM
        self.speechService = speechService
    }

    public var body: some View {
        VStack(spacing: 12) {
            Picker("表示", selection: $mode) {
                Text("月").tag(CalendarDisplayMode.month)
                Text("週").tag(CalendarDisplayMode.week)
            }
            .pickerStyle(.segmented)

            HStack {
                Button { move(by: -1) } label: {
                    Image(systemName: "chevron.left")
                }

                Spacer()
                Text(headerTitle)
                    .font(.headline)
                Spacer()

                Button { move(by: 1) } label: {
                    Image(systemName: "chevron.right")
                }
            }

            Button("Today") { anchorDate = .now }
                .font(.caption)

            if mode == .month {
                MonthView(monthDate: anchorDate, calendarVM: calendarVM, onSelectDate: select(date:))
            } else {
                WeekView(weekStartDate: anchorDate, calendarVM: calendarVM, onSelectDate: select(date:))
            }

            NavigationLink(isActive: $showDayDetail) {
                DayDetailView(date: selectedDate, calendarVM: calendarVM, speechService: speechService)
            } label: {
                EmptyView()
            }

            Spacer(minLength: 0)
        }
        .padding()
        .navigationTitle("カレンダー")
    }

    private func select(date: Date) {
        selectedDate = date
        showDayDetail = true
    }

    private var headerTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = mode == .month ? "yyyy年M月" : "M/d週"
        let date = mode == .month ? calendarVM.startOfMonth(for: anchorDate) : calendarVM.startOfWeek(for: anchorDate)
        return formatter.string(from: date)
    }

    private func move(by value: Int) {
        if mode == .month {
            anchorDate = calendarVM.addMonths(value, to: anchorDate)
        } else {
            anchorDate = calendarVM.addWeeks(value, to: anchorDate)
        }
    }
}

#endif
