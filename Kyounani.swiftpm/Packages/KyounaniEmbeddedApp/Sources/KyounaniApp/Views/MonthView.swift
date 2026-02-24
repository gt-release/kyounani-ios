#if canImport(SwiftUI)
import SwiftUI

public struct MonthView: View {
    @EnvironmentObject private var appVM: AppViewModel
    @Environment(\.kyounaniTheme) private var theme
    @ObservedObject var calendarVM: CalendarViewModel

    let monthDate: Date
    let selectedDate: Date?
    let onSelectDate: (Date) -> Void

    public init(monthDate: Date, selectedDate: Date?, calendarVM: CalendarViewModel, onSelectDate: @escaping (Date) -> Void) {
        self.monthDate = monthDate
        self.selectedDate = selectedDate
        self.calendarVM = calendarVM
        self.onSelectDate = onSelectDate
    }

    public var body: some View {
        let dates = calendarVM.monthGridDates(for: monthDate)
        let summaries = calendarVM.monthSummaries(for: monthDate, childFilter: appVM.filter, includeDraft: appVM.parentModeUnlocked)

        VStack(spacing: 8) {
            HStack {
                ForEach(["日", "月", "火", "水", "木", "金", "土"], id: \.self) { day in
                    Text(day)
                        .font(.caption.bold())
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
                ForEach(dates, id: \.self) { date in
                    let dayStart = calendarVM.startOfDay(for: date)
                    let summary = summaries[dayStart] ?? DayEventSummary(topOccurrences: [], remainingCount: 0)
                    let dayKind = dayKindForDate(date)
                    Button {
                        onSelectDate(date)
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("\(calendarVM.dayNumber(date))")
                                .font(.footnote.bold())
                                .foregroundStyle(theme.dayTextColor(for: dayKind))

                            DayCellEventTokensView(summary: summary)
                            Spacer(minLength: 0)
                        }
                        .padding(6)
                        .frame(maxWidth: .infinity, minHeight: 92, alignment: .topLeading)
                        .background(theme.dayBackgroundColor(for: dayKind))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(dayKind == .today ? theme.colors.accent : Color.clear, lineWidth: 2)
                        )
                        .cornerRadius(10)
                        .opacity(calendarVM.isSameMonth(date, monthDate) ? 1.0 : 0.45)
                    }
                    .buttonStyle(.plain)
                    .minTapTarget()
                }
            }
        }
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
