#if canImport(SwiftUI)
import SwiftUI

public struct CalendarRootView: View {
    @EnvironmentObject private var appVM: AppViewModel
    @Environment(\.kyounaniTheme) private var theme
    @State private var mode: CalendarDisplayMode = .month
    @State private var anchorDate: Date = .now
    @State private var selectedDate: Date?
    @State private var openEditorOnQuickAdd = false

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
            .padding(8)
            .cardStyle(background: theme.colors.tabBackground)

            HStack(spacing: 12) {
                Button { move(by: -1) } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3.bold())
                }
                .minTapTarget()

                Text(headerTitle)
                    .font(theme.fonts.calendarHeader)
                    .frame(maxWidth: .infinity)

                Button { move(by: 1) } label: {
                    Image(systemName: "chevron.right")
                        .font(.title3.bold())
                }
                .minTapTarget()
            }
            .padding(theme.spacing.cardPadding)
            .cardStyle(background: theme.colors.tabBackground)

            HStack {
                Button("きょう") { anchorDate = .now }
                    .font(theme.fonts.supporting)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .cardStyle(background: theme.colors.peekCard)
                Spacer()
            }

            Group {
                if mode == .month {
                    MonthView(monthDate: anchorDate, selectedDate: selectedDate, calendarVM: calendarVM, onSelectDate: select(date:))
                } else {
                    WeekView(weekStartDate: anchorDate, selectedDate: selectedDate, calendarVM: calendarVM, onSelectDate: select(date:))
                }
            }
            .padding(theme.spacing.cardPadding)
            .cardStyle(background: theme.colors.tabBackground)

            Spacer(minLength: 0)
        }
        .padding(theme.spacing.screenPadding)
        .background(KidSoftBackground())
        .navigationTitle("カレンダー")
        .onChange(of: appVM.quickAddRequestID) {
            guard appVM.parentModeUnlocked else { return }
            let today = calendarVM.startOfDay(for: .now)
            anchorDate = today
            selectedDate = today
            openEditorOnQuickAdd = true
        }
        .navigationDestination(isPresented: dayDetailIsPresented) {
            if let date = selectedDate {
                DayDetailView(date: date, calendarVM: calendarVM, speechService: speechService, repository: repository, openEditorImmediately: openEditorOnQuickAdd)
            }
        }
    }

    private var dayDetailIsPresented: Binding<Bool> {
        Binding(
            get: { selectedDate != nil },
            set: { isPresented in
                if !isPresented {
                    selectedDate = nil
                    openEditorOnQuickAdd = false
                }
            }
        )
    }

    private func select(date: Date) {
        openEditorOnQuickAdd = false
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
