#if canImport(SwiftUI)
import Foundation

public struct DayEventSummary {
    public var topOccurrences: [EventOccurrence]
    public var remainingCount: Int

    public init(topOccurrences: [EventOccurrence], remainingCount: Int) {
        self.topOccurrences = topOccurrences
        self.remainingCount = remainingCount
    }
}

public enum CalendarDisplayMode: String, CaseIterable, Identifiable {
    case month
    case week

    public var id: String { rawValue }
}

public struct EventListPresenter {
    public static func summarizeDay(
        _ occurrences: [EventOccurrence],
        maxVisibleCount: Int = 2,
        sortByAllDayFirst: Bool = true
    ) -> DayEventSummary {
        let sorted = occurrences.sorted { lhs, rhs in
            if sortByAllDayFirst, lhs.baseEvent.isAllDay != rhs.baseEvent.isAllDay {
                return lhs.baseEvent.isAllDay && !rhs.baseEvent.isAllDay
            }
            return lhs.displayStart < rhs.displayStart
        }

        let top = Array(sorted.prefix(maxVisibleCount))
        return DayEventSummary(topOccurrences: top, remainingCount: max(0, sorted.count - top.count))
    }
}

@MainActor
public final class CalendarViewModel: ObservableObject {
    @Published public private(set) var todayOccurrences: [EventOccurrence] = []
    @Published public private(set) var weekPeekOccurrences: [EventOccurrence] = []

    private let repository: EventRepository
    private let engine: RecurrenceEngine
    private let holidayService: HolidayService
    private let calendar: Calendar

    public init(repository: EventRepository, engine: RecurrenceEngine, holidayService: HolidayService) {
        self.repository = repository
        self.engine = engine
        self.holidayService = holidayService

        var jpCalendar = Calendar(identifier: .gregorian)
        jpCalendar.locale = Locale(identifier: "ja_JP")
        jpCalendar.timeZone = TimeZone(identifier: "Asia/Tokyo") ?? .current
        jpCalendar.firstWeekday = 1 // Sunday
        self.calendar = jpCalendar
    }

    public func refresh(childFilter: ChildScope, includeDraft: Bool) {
        let now = Date()
        let startToday = calendar.startOfDay(for: now)
        let endToday = calendar.date(byAdding: .day, value: 1, to: startToday)!
        let endWeek = calendar.date(byAdding: .day, value: 7, to: startToday)!

        todayOccurrences = occurrences(in: DateInterval(start: startToday, end: endToday), childFilter: childFilter, includeDraft: includeDraft)
        weekPeekOccurrences = occurrences(in: DateInterval(start: endToday, end: endWeek), childFilter: childFilter, includeDraft: includeDraft)
    }

    public func daySummary(on date: Date, childFilter: ChildScope, includeDraft: Bool) -> DayEventSummary {
        EventListPresenter.summarizeDay(dayOccurrences(on: date, childFilter: childFilter, includeDraft: includeDraft))
    }

    public func dayOccurrences(on date: Date, childFilter: ChildScope, includeDraft: Bool) -> [EventOccurrence] {
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        return occurrences(in: DateInterval(start: start, end: end), childFilter: childFilter, includeDraft: includeDraft)
    }

    public func holidayName(for date: Date) -> String? {
        holidayService.holidayName(on: date)
    }

    public func isHoliday(_ date: Date) -> Bool {
        holidayService.isHoliday(date)
    }

    public func isSaturday(_ date: Date) -> Bool {
        calendar.component(.weekday, from: date) == 7
    }

    public func isSunday(_ date: Date) -> Bool {
        calendar.component(.weekday, from: date) == 1
    }

    public func startOfMonth(for date: Date) -> Date {
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components) ?? date
    }

    public func addMonths(_ value: Int, to date: Date) -> Date {
        calendar.date(byAdding: .month, value: value, to: date) ?? date
    }

    public func startOfWeek(for date: Date) -> Date {
        let weekday = calendar.component(.weekday, from: date)
        let offset = weekday - calendar.firstWeekday
        return calendar.date(byAdding: .day, value: -offset, to: calendar.startOfDay(for: date)) ?? date
    }

    public func addWeeks(_ value: Int, to date: Date) -> Date {
        calendar.date(byAdding: .day, value: value * 7, to: date) ?? date
    }

    public func monthGridDates(for month: Date) -> [Date] {
        let monthStart = startOfMonth(for: month)
        guard let monthRange = calendar.range(of: .day, in: .month, for: monthStart) else { return [] }

        let leadingDays = (calendar.component(.weekday, from: monthStart) - calendar.firstWeekday + 7) % 7
        let gridStart = calendar.date(byAdding: .day, value: -leadingDays, to: monthStart) ?? monthStart
        let visibleCellCount = Int(ceil(Double(leadingDays + monthRange.count) / 7.0) * 7.0)

        return (0..<visibleCellCount).compactMap { calendar.date(byAdding: .day, value: $0, to: gridStart) }
    }

    public func weekDates(for weekStart: Date) -> [Date] {
        (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek(for: weekStart)) }
    }

    public func isSameMonth(_ lhs: Date, _ rhs: Date) -> Bool {
        calendar.isDate(lhs, equalTo: rhs, toGranularity: .month)
    }

    public func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }

    public func occurrences(in range: DateInterval, childFilter: ChildScope, includeDraft: Bool) -> [EventOccurrence] {
        engine.occurrences(
            for: repository.fetchEvents(),
            exceptions: repository.fetchExceptions(),
            in: range,
            childFilter: childFilter,
            includeDraft: includeDraft
        )
    }
}

#endif
