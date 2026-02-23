#if canImport(SwiftUI)
import Foundation

@MainActor
public final class CalendarViewModel: ObservableObject {
    @Published public private(set) var todayOccurrences: [EventOccurrence] = []
    @Published public private(set) var weekPeekOccurrences: [EventOccurrence] = []

    private let repository: EventRepository
    private let engine: RecurrenceEngine

    public init(repository: EventRepository, engine: RecurrenceEngine) {
        self.repository = repository
        self.engine = engine
    }

    public func refresh(childFilter: ChildScope, includeDraft: Bool) {
        let now = Date()
        let calendar = Calendar(identifier: .gregorian)
        let startToday = calendar.startOfDay(for: now)
        let endToday = calendar.date(byAdding: .day, value: 1, to: startToday)!
        let endWeek = calendar.date(byAdding: .day, value: 7, to: startToday)!

        todayOccurrences = engine.occurrences(
            for: repository.fetchEvents(),
            exceptions: repository.fetchExceptions(),
            in: DateInterval(start: startToday, end: endToday),
            childFilter: childFilter,
            includeDraft: includeDraft
        )

        weekPeekOccurrences = engine.occurrences(
            for: repository.fetchEvents(),
            exceptions: repository.fetchExceptions(),
            in: DateInterval(start: endToday, end: endWeek),
            childFilter: childFilter,
            includeDraft: includeDraft
        )
    }
}

#endif
