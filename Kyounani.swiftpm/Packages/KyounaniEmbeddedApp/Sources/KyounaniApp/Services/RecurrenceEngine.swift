import Foundation

public final class RecurrenceEngine {
    private let calendar: Calendar
    private let holidayService: HolidayService

    public init(calendar: Calendar = Calendar(identifier: .gregorian), holidayService: HolidayService) {
        var jpCalendar = calendar
        jpCalendar.timeZone = TimeZone(identifier: "Asia/Tokyo") ?? .current
        self.calendar = jpCalendar
        self.holidayService = holidayService
    }

    public func occurrences(
        for events: [Event],
        exceptions: [EventException],
        in range: DateInterval,
        childFilter: ChildScope,
        includeDraft: Bool
    ) -> [EventOccurrence] {
        var generated: [EventOccurrence] = []
        for event in events {
            guard includeDraft || event.visibility == .published else { continue }
            guard event.childScope.matches(childFilter) else { continue }
            generated.append(contentsOf: eventOccurrences(for: event, in: range))
        }
        return apply(exceptions: exceptions, to: generated, in: range)
            .sorted(by: { $0.displayStart < $1.displayStart })
    }

    private func eventOccurrences(for event: Event, in range: DateInterval) -> [EventOccurrence] {
        guard let rule = event.recurrenceRule else {
            return range.contains(event.startDateTime)
            ? [EventOccurrence(baseEvent: event, occurrenceDate: event.startDateTime, displayStart: event.startDateTime)]
            : []
        }

        var results: [EventOccurrence] = []
        var day = calendar.startOfDay(for: max(rule.startDate, range.start))
        let end = min(rule.endDate ?? range.end, range.end)

        while day < end {
            let weekday = calendar.component(.weekday, from: day)
            if rule.weekdays.contains(weekday) {
                if !(rule.skipHolidays && holidayService.isHoliday(day)) {
                    let time = calendar.dateComponents([.hour, .minute], from: event.startDateTime)
                    let start = calendar.date(bySettingHour: time.hour ?? 0, minute: time.minute ?? 0, second: 0, of: day) ?? day
                    results.append(EventOccurrence(baseEvent: event, occurrenceDate: day, displayStart: start))
                }
            }
            day = calendar.date(byAdding: .day, value: 1, to: day) ?? day
        }
        return results
    }

    private func apply(exceptions: [EventException], to occurrences: [EventOccurrence], in range: DateInterval) -> [EventOccurrence] {
        var output = occurrences
        for exception in exceptions {
            switch exception.kind {
            case .delete:
                guard range.contains(exception.occurrenceDate) else { continue }
                output.removeAll {
                    $0.baseEvent.id == exception.eventId && calendar.isDate($0.occurrenceDate, inSameDayAs: exception.occurrenceDate)
                }
            case .override:
                guard range.contains(exception.occurrenceDate) else { continue }
                output.removeAll {
                    $0.baseEvent.id == exception.eventId && calendar.isDate($0.occurrenceDate, inSameDayAs: exception.occurrenceDate)
                }
                if let override = exception.overrideEvent {
                    output.append(EventOccurrence(baseEvent: override, occurrenceDate: exception.occurrenceDate, displayStart: override.startDateTime))
                }
            case .splitFromThisDate:
                output.removeAll {
                    $0.baseEvent.id == exception.eventId && $0.occurrenceDate >= calendar.startOfDay(for: exception.occurrenceDate)
                }
                if let override = exception.overrideEvent {
                    let splitStart = calendar.startOfDay(for: exception.occurrenceDate)
                    let newOnes = eventOccurrences(for: override, in: range).filter { $0.occurrenceDate >= splitStart }
                    output.append(contentsOf: newOnes)
                }
            }
        }
        return output
    }
}
