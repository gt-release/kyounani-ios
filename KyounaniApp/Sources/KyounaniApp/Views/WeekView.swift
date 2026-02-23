#if canImport(SwiftUI)
import SwiftUI

public struct WeekView: View {
    @EnvironmentObject private var appVM: AppViewModel
    @ObservedObject var calendarVM: CalendarViewModel

    let weekStartDate: Date
    let onSelectDate: (Date) -> Void

    public init(weekStartDate: Date, calendarVM: CalendarViewModel, onSelectDate: @escaping (Date) -> Void) {
        self.weekStartDate = weekStartDate
        self.calendarVM = calendarVM
        self.onSelectDate = onSelectDate
    }

    public var body: some View {
        let weekDates = calendarVM.weekDates(for: weekStartDate)

        HStack(alignment: .top, spacing: 8) {
            ForEach(weekDates, id: \.self) { date in
                let summary = calendarVM.daySummary(on: date, childFilter: appVM.filter, includeDraft: appVM.parentModeUnlocked)
                Button {
                    onSelectDate(date)
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(weekdayAndDay(date))
                            .font(.footnote.bold())
                            .foregroundStyle(dayNumberColor(date))

                        DayCellEventTokensView(summary: summary)
                        Spacer(minLength: 0)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, minHeight: 140, alignment: .topLeading)
                    .background(dayBackgroundColor(date))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(calendarVM.isToday(date) ? Color.accentColor : Color.clear, lineWidth: 2)
                    )
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func weekdayAndDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "E d"
        return formatter.string(from: date)
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
