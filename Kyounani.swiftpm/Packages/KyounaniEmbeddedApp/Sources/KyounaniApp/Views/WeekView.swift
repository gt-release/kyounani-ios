#if canImport(SwiftUI)
import SwiftUI

public struct WeekView: View {
    @EnvironmentObject private var appVM: AppViewModel
    @Environment(\.kyounaniTheme) private var theme
    @ObservedObject var calendarVM: CalendarViewModel

    let weekStartDate: Date
    let selectedDate: Date?
    let onSelectDate: (Date) -> Void

    public init(weekStartDate: Date, selectedDate: Date?, calendarVM: CalendarViewModel, onSelectDate: @escaping (Date) -> Void) {
        self.weekStartDate = weekStartDate
        self.selectedDate = selectedDate
        self.calendarVM = calendarVM
        self.onSelectDate = onSelectDate
    }

    public var body: some View {
        let weekDates = calendarVM.weekDates(for: weekStartDate)
        let summaries = calendarVM.weekSummaries(for: weekStartDate, childFilter: appVM.filter, includeDraft: appVM.parentModeUnlocked)

        HStack(alignment: .top, spacing: 10) {
            ForEach(weekDates, id: \.self) { date in
                let dayStart = calendarVM.startOfDay(for: date)
                let summary = summaries[dayStart] ?? DayEventSummary(topOccurrences: [], remainingCount: 0)
                let dayKind = dayKindForDate(date)
                Button {
                    onSelectDate(date)
                } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(weekdayAndDay(date))
                            .font(theme.fonts.supporting)
                            .foregroundStyle(theme.dayTextColor(for: dayKind))

                        DayCellEventTokensView(summary: summary)
                        Spacer(minLength: 0)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, minHeight: 160, alignment: .topLeading)
                    .background(theme.dayBackgroundColor(for: dayKind))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(dayKind == .today ? theme.colors.accent : Color.clear, lineWidth: 2)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
                .minTapTarget()
            }
        }
    }

    private func weekdayAndDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "E d"
        return formatter.string(from: date)
    }

    private func dayKindForDate(_ date: Date) -> KyounaniTheme.DayKind {
        let dayStart = calendarVM.startOfDay(for: date)
        if let selectedDate, calendarVM.startOfDay(for: selectedDate) == dayStart { return .selected }
        if calendarVM.isToday(date) { return .today }
        if calendarVM.isHoliday(date) { return .holiday }
        if calendarVM.isSunday(date) || calendarVM.isSaturday(date) { return .weekend }
        return .weekday
    }
}

#endif
