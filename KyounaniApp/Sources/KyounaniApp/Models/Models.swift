import Foundation

public enum ChildScope: String, Codable, CaseIterable, Identifiable {
    case son
    case daughter
    case both

    public var id: String { rawValue }

    public func matches(_ filter: ChildScope) -> Bool {
        switch (self, filter) {
        case (_, .both): return true
        case (.both, _): return true
        default: return self == filter
        }
    }
}

public enum Visibility: String, Codable, CaseIterable {
    case draft
    case published
}

public struct WeeklyRecurrenceRule: Codable, Equatable {
    public var startDate: Date
    public var endDate: Date?
    public var weekdays: Set<Int> // 1 = Sunday ... 7 = Saturday
    public var skipHolidays: Bool

    public init(startDate: Date, endDate: Date?, weekdays: Set<Int>, skipHolidays: Bool) {
        self.startDate = startDate
        self.endDate = endDate
        self.weekdays = weekdays
        self.skipHolidays = skipHolidays
    }
}

public struct Event: Identifiable, Codable, Equatable {
    public var id: UUID
    public var title: String
    public var stampId: UUID
    public var childScope: ChildScope
    public var visibility: Visibility
    public var isAllDay: Bool
    public var startDateTime: Date
    public var durationMinutes: Int?
    public var recurrenceRule: WeeklyRecurrenceRule?
    public var createdAt: Date
    public var updatedAt: Date

    public init(id: UUID = UUID(), title: String, stampId: UUID, childScope: ChildScope, visibility: Visibility, isAllDay: Bool, startDateTime: Date, durationMinutes: Int?, recurrenceRule: WeeklyRecurrenceRule?, createdAt: Date = .now, updatedAt: Date = .now) {
        self.id = id
        self.title = title
        self.stampId = stampId
        self.childScope = childScope
        self.visibility = visibility
        self.isAllDay = isAllDay
        self.startDateTime = startDateTime
        self.durationMinutes = durationMinutes
        self.recurrenceRule = recurrenceRule
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public enum ExceptionKind: String, Codable {
    case override
    case delete
    case splitFromThisDate
}

public struct EventException: Identifiable, Codable, Equatable {
    public var id: UUID
    public var eventId: UUID
    public var occurrenceDate: Date
    public var kind: ExceptionKind
    public var overrideEvent: Event?
    public var splitRule: WeeklyRecurrenceRule?

    public init(id: UUID = UUID(), eventId: UUID, occurrenceDate: Date, kind: ExceptionKind, overrideEvent: Event?, splitRule: WeeklyRecurrenceRule?) {
        self.id = id
        self.eventId = eventId
        self.occurrenceDate = occurrenceDate
        self.kind = kind
        self.overrideEvent = overrideEvent
        self.splitRule = splitRule
    }
}

public struct Stamp: Identifiable, Codable, Equatable {
    public var id: UUID
    public var name: String
    public var imagePath: String

    public init(id: UUID = UUID(), name: String, imagePath: String) {
        self.id = id
        self.name = name
        self.imagePath = imagePath
    }
}

public struct EventOccurrence: Identifiable, Equatable {
    public var id: String { "\(baseEvent.id.uuidString)-\(occurrenceDate.timeIntervalSince1970)" }
    public var baseEvent: Event
    public var occurrenceDate: Date
    public var displayStart: Date
}
