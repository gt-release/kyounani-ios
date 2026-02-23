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

public enum StampKind: String, Codable {
    case builtin
    case user
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
    private enum CodingKeys: String, CodingKey {
        case id, title, stampId, childScope, visibility, isAllDay, startDateTime, durationMinutes, recurrenceRule, createdAt, updatedAt
    }
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

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try container.decode(String.self, forKey: .title)
        stampId = try container.decodeIfPresent(UUID.self, forKey: .stampId) ?? Stamp.defaultStampId
        childScope = try container.decode(ChildScope.self, forKey: .childScope)
        visibility = try container.decode(Visibility.self, forKey: .visibility)
        isAllDay = try container.decode(Bool.self, forKey: .isAllDay)
        startDateTime = try container.decode(Date.self, forKey: .startDateTime)
        durationMinutes = try container.decodeIfPresent(Int.self, forKey: .durationMinutes)
        recurrenceRule = try container.decodeIfPresent(WeeklyRecurrenceRule.self, forKey: .recurrenceRule)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? .now
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? .now
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(stampId, forKey: .stampId)
        try container.encode(childScope, forKey: .childScope)
        try container.encode(visibility, forKey: .visibility)
        try container.encode(isAllDay, forKey: .isAllDay)
        try container.encode(startDateTime, forKey: .startDateTime)
        try container.encodeIfPresent(durationMinutes, forKey: .durationMinutes)
        try container.encodeIfPresent(recurrenceRule, forKey: .recurrenceRule)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
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
    public static let defaultStampId = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!

    public var id: UUID
    public var name: String
    public var kind: StampKind
    public var imageLocation: String

    public init(id: UUID = UUID(), name: String, kind: StampKind, imageLocation: String) {
        self.id = id
        self.name = name
        self.kind = kind
        self.imageLocation = imageLocation
    }
}

public struct EventOccurrence: Identifiable, Equatable {
    public var id: String { "\(baseEvent.id.uuidString)-\(occurrenceDate.timeIntervalSince1970)" }
    public var baseEvent: Event
    public var occurrenceDate: Date
    public var displayStart: Date
}
