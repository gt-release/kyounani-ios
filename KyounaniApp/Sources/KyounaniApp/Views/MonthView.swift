#if canImport(SwiftUI)
import SwiftUI

public struct MonthView: View {
    @EnvironmentObject private var appVM: AppViewModel
    @ObservedObject var calendarVM: CalendarViewModel

    let monthDate: Date
    let onSelectDate: (Date) -> Void

    public init(monthDate: Date, calendarVM: CalendarViewModel, onSelectDate: @escaping (Date) -> Void) {
        self.monthDate = monthDate
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
                    Button {
                        onSelectDate(date)
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("\(calendarVM.dayNumber(date))")
                                .font(.footnote.bold())
                                .foregroundStyle(dayNumberColor(date))

                            DayCellEventTokensView(summary: summary)
                            Spacer(minLength: 0)
                        }
                        .padding(6)
                        .frame(maxWidth: .infinity, minHeight: 92, alignment: .topLeading)
                        .background(dayBackgroundColor(date))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(calendarVM.isToday(date) ? Color.accentColor : Color.clear, lineWidth: 2)
                        )
                        .cornerRadius(10)
                        .opacity(calendarVM.isSameMonth(date, monthDate) ? 1.0 : 0.45)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func dayNumberColor(_ date: Date) -> Color {
        if calendarVM.isHoliday(date) || calendarVM.isSunday(date) { return .red }
        if calendarVM.isSaturday(date) { return .blue }
        return .primary
    }

    private func dayBackgroundColor(_ date: Date) -> Color {
        if calendarVM.isHoliday(date) { return .red.opacity(0.12) }
        if calendarVM.isSunday(date) { return .red.opacity(0.08) }
        if calendarVM.isSaturday(date) { return .blue.opacity(0.08) }
        return Color.gray.opacity(0.08)
    }
}

#endif
