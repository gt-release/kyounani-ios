#if canImport(SwiftUI)
import SwiftUI

public struct CalendarRootView: View {
    @Environment(\.kyounaniTheme) private var theme
    @State private var mode: CalendarDisplayMode = .month
    @State private var anchorDate: Date = .now
    @State private var selectedDate: Date?

    @ObservedObject var calendarVM: CalendarViewModel
    @ObservedObject var speechService: SpeechService
    @ObservedObject var repository: EventRepositoryBase

    public init(calendarVM: CalendarViewModel, speechService: SpeechService, repository: EventRepositoryBase) {
        self.calendarVM = calendarVM
        self.speechService = speechService
        self.repository = repository
    }

    public var body: some View {
        VStack(spacing: theme.spacing.itemGap) {
            Picker("表示", selection: $mode) {
                Text("月").tag(CalendarDisplayMode.month)
                Text("週").tag(CalendarDisplayMode.week)
            }
            .pickerStyle(.segmented)

            HStack {
                Button { move(by: -1) } label: {
                    Image(systemName: "chevron.left")
                }
                .minTapTarget()

                Spacer()
                Text(headerTitle)
                    .font(theme.fonts.calendarHeader)
                Spacer()

                Button { move(by: 1) } label: {
                    Image(systemName: "chevron.right")
                }
                .minTapTarget()
            }

            Button("Today") { anchorDate = .now }
                .font(theme.fonts.supporting)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .cardStyle(background: theme.colors.emptyCard)
                .minTapTarget()

            if mode == .month {
                MonthView(monthDate: anchorDate, selectedDate: selectedDate, calendarVM: calendarVM, onSelectDate: select(date:))
            } else {
                WeekView(weekStartDate: anchorDate, selectedDate: selectedDate, calendarVM: calendarVM, onSelectDate: select(date:))
            }

            Spacer(minLength: 0)
        }
        .padding(theme.spacing.screenPadding)
        .navigationTitle("カレンダー")
        .navigationDestination(isPresented: dayDetailIsPresented) {
            if let date = selectedDate {
                DayDetailView(date: date, calendarVM: calendarVM, speechService: speechService, repository: repository)
            }
        }
    }

    private var dayDetailIsPresented: Binding<Bool> {
        Binding(
            get: { selectedDate != nil },
            set: { isPresented in
                if !isPresented {
                    selectedDate = nil
                }
            }
        )
    }

    private func select(date: Date) {
        selectedDate = calendarVM.startOfDay(for: date)
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
