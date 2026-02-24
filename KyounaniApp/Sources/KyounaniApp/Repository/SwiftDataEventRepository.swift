#if canImport(SwiftData) && canImport(SwiftUI)
import Foundation
import SwiftData

@Model
final class PersistentStamp {
    @Attribute(.unique) var id: UUID
    var name: String
    var kindRaw: String
    var imageLocation: String
    var isBuiltin: Bool
    var lastUsedAt: Date?
    var sortOrder: Int?

    init(id: UUID, name: String, kindRaw: String, imageLocation: String, isBuiltin: Bool, lastUsedAt: Date? = nil, sortOrder: Int? = nil) {
        self.id = id
        self.name = name
        self.kindRaw = kindRaw
        self.imageLocation = imageLocation
        self.isBuiltin = isBuiltin
        self.lastUsedAt = lastUsedAt
        self.sortOrder = sortOrder
    }
}

@Model
final class PersistentEventSeries {
    @Attribute(.unique) var id: UUID
    var title: String
    var stampId: UUID
    var childScopeRaw: String
    var visibilityRaw: String
    var isAllDay: Bool
    var startDateTime: Date
    var durationMinutes: Int?
    var createdAt: Date
    var updatedAt: Date

    var recurrenceStartDate: Date?
    var recurrenceEndDate: Date?
    var recurrenceWeekdays: [Int]
    var recurrenceSkipHolidays: Bool

    init(event: Event) {
        id = event.id
        title = event.title
        stampId = event.stampId
        childScopeRaw = event.childScope.rawValue
        visibilityRaw = event.visibility.rawValue
        isAllDay = event.isAllDay
        startDateTime = event.startDateTime
        durationMinutes = event.durationMinutes
        createdAt = event.createdAt
        updatedAt = event.updatedAt
        recurrenceStartDate = event.recurrenceRule?.startDate
        recurrenceEndDate = event.recurrenceRule?.endDate
        recurrenceWeekdays = event.recurrenceRule.map { Array($0.weekdays).sorted() } ?? []
        recurrenceSkipHolidays = event.recurrenceRule?.skipHolidays ?? false
    }

    func apply(_ event: Event) {
        title = event.title
        stampId = event.stampId
        childScopeRaw = event.childScope.rawValue
        visibilityRaw = event.visibility.rawValue
        isAllDay = event.isAllDay
        startDateTime = event.startDateTime
        durationMinutes = event.durationMinutes
        createdAt = event.createdAt
        updatedAt = event.updatedAt
        recurrenceStartDate = event.recurrenceRule?.startDate
        recurrenceEndDate = event.recurrenceRule?.endDate
        recurrenceWeekdays = event.recurrenceRule.map { Array($0.weekdays).sorted() } ?? []
        recurrenceSkipHolidays = event.recurrenceRule?.skipHolidays ?? false
    }
}

@Model
final class PersistentEventException {
    @Attribute(.unique) var id: UUID
    var eventId: UUID
    var occurrenceDate: Date
    var kindRaw: String
    var overrideEventData: Data?
    var splitRuleData: Data?

    init(exception: EventException) {
        id = exception.id
        eventId = exception.eventId
        occurrenceDate = exception.occurrenceDate
        kindRaw = exception.kind.rawValue
        let encoder = JSONEncoder()
        overrideEventData = try? encoder.encode(exception.overrideEvent)
        splitRuleData = try? encoder.encode(exception.splitRule)
    }

    func apply(_ exception: EventException) {
        eventId = exception.eventId
        occurrenceDate = exception.occurrenceDate
        kindRaw = exception.kind.rawValue
        let encoder = JSONEncoder()
        overrideEventData = try? encoder.encode(exception.overrideEvent)
        splitRuleData = try? encoder.encode(exception.splitRule)
    }
}

private struct BuiltinStampDefinition: Codable {
    var id: UUID
    var name: String
    var symbolName: String
}


@MainActor
public final class SwiftDataEventRepository: EventRepositoryBase {
    private let context: ModelContext
    private let seedVersionKey = "kyounani.seed.version"
    private let seedVersion = 1

    public init(context: ModelContext) {
        self.context = context
        super.init(repositoryKind: .swiftData)
        seedBuiltinStampsIfNeeded()
    }

    public override func fetchEvents() -> [Event] {
        let descriptor = FetchDescriptor<PersistentEventSeries>(sortBy: [SortDescriptor(\.startDateTime)])
        let rows = (try? context.fetch(descriptor)) ?? []
        return rows.map(mapEvent)
    }

    public override func fetchExceptions() -> [EventException] {
        let descriptor = FetchDescriptor<PersistentEventException>(sortBy: [SortDescriptor(\.occurrenceDate)])
        let rows = (try? context.fetch(descriptor)) ?? []
        return rows.map(mapException)
    }

    public override func fetchStamps() -> [Stamp] {
        let descriptor = FetchDescriptor<PersistentStamp>(sortBy: [SortDescriptor(\.name)])
        let rows = (try? context.fetch(descriptor)) ?? []
        return rows.map(mapStamp)
    }

    public override func save(event: Event) {
        objectWillChange.send()
        let descriptor = FetchDescriptor<PersistentEventSeries>(predicate: #Predicate { $0.id == event.id })
        if let existing = (try? context.fetch(descriptor))?.first {
            existing.apply(event)
        } else {
            context.insert(PersistentEventSeries(event: event))
        }
        do {
            try context.save()
            clearLastError()
        } catch {
            recordError(error)
        }
    }

    public override func save(exception: EventException) {
        objectWillChange.send()
        let descriptor = FetchDescriptor<PersistentEventException>(predicate: #Predicate { $0.id == exception.id })
        if let existing = (try? context.fetch(descriptor))?.first {
            existing.apply(exception)
        } else {
            context.insert(PersistentEventException(exception: exception))
        }
        do {
            try context.save()
            clearLastError()
        } catch {
            recordError(error)
        }
    }

    public override func save(stamp: Stamp) {
        objectWillChange.send()
        let descriptor = FetchDescriptor<PersistentStamp>(predicate: #Predicate { $0.id == stamp.id })
        if let existing = (try? context.fetch(descriptor))?.first {
            existing.name = stamp.name
            existing.kindRaw = stamp.kind.rawValue
            existing.imageLocation = stamp.imageLocation
            existing.isBuiltin = stamp.isBuiltin
            existing.lastUsedAt = stamp.lastUsedAt
            existing.sortOrder = stamp.sortOrder
        } else {
            context.insert(PersistentStamp(id: stamp.id, name: stamp.name, kindRaw: stamp.kind.rawValue, imageLocation: stamp.imageLocation, isBuiltin: stamp.isBuiltin, lastUsedAt: stamp.lastUsedAt, sortOrder: stamp.sortOrder))
        }
        do {
            try context.save()
            clearLastError()
        } catch {
            recordError(error)
        }
    }

    public override func delete(eventID: UUID) {
        objectWillChange.send()
        let eventDescriptor = FetchDescriptor<PersistentEventSeries>(predicate: #Predicate { $0.id == eventID })
        if let existing = (try? context.fetch(eventDescriptor))?.first {
            context.delete(existing)
        }

        let exceptionDescriptor = FetchDescriptor<PersistentEventException>(predicate: #Predicate { $0.eventId == eventID })
        let exceptions = (try? context.fetch(exceptionDescriptor)) ?? []
        for row in exceptions { context.delete(row) }
        do {
            try context.save()
            clearLastError()
        } catch {
            recordError(error)
        }
    }

    public override func delete(stampID: UUID) {
        objectWillChange.send()
        let descriptor = FetchDescriptor<PersistentStamp>(predicate: #Predicate { $0.id == stampID })
        if let existing = (try? context.fetch(descriptor))?.first {
            context.delete(existing)
            do {
                try context.save()
                clearLastError()
            } catch {
                recordError(error)
            }
        }
    }

    public override func replaceAll(events: [Event], exceptions: [EventException], stamps: [Stamp]) {
        objectWillChange.send()

        let existingEvents = (try? context.fetch(FetchDescriptor<PersistentEventSeries>())) ?? []
        for row in existingEvents { context.delete(row) }

        let existingExceptions = (try? context.fetch(FetchDescriptor<PersistentEventException>())) ?? []
        for row in existingExceptions { context.delete(row) }

        let existingStamps = (try? context.fetch(FetchDescriptor<PersistentStamp>())) ?? []
        for row in existingStamps { context.delete(row) }

        for stamp in stamps {
            context.insert(PersistentStamp(id: stamp.id, name: stamp.name, kindRaw: stamp.kind.rawValue, imageLocation: stamp.imageLocation, isBuiltin: stamp.isBuiltin, lastUsedAt: stamp.lastUsedAt, sortOrder: stamp.sortOrder))
        }

        for event in events {
            context.insert(PersistentEventSeries(event: event))
        }

        for exception in exceptions {
            context.insert(PersistentEventException(exception: exception))
        }

        do {
            try context.save()
            clearLastError()
        } catch {
            recordError(error)
        }
    }

    private func seedBuiltinStampsIfNeeded() {
        guard UserDefaults.standard.integer(forKey: seedVersionKey) < seedVersion else { return }
        for definition in loadBuiltinDefinitions() {
            let descriptor = FetchDescriptor<PersistentStamp>(predicate: #Predicate { $0.id == definition.id })
            let exists = ((try? context.fetch(descriptor)) ?? []).isEmpty == false
            guard !exists else { continue }
            context.insert(PersistentStamp(
                id: definition.id,
                name: definition.name,
                kindRaw: StampKind.systemSymbol.rawValue,
                imageLocation: "symbol:\(definition.symbolName)",
                isBuiltin: true,
                lastUsedAt: nil,
                sortOrder: nil
            ))
        }
        do {
            try context.save()
            clearLastError()
        } catch {
            recordError(error)
        }
        UserDefaults.standard.set(seedVersion, forKey: seedVersionKey)
    }

    private func loadBuiltinDefinitions() -> [BuiltinStampDefinition] {
        let bundles = ResourceBundleLocator.candidateBundles()
        for bundle in bundles {
            guard let url = bundle.url(forResource: "builtin_stamps", withExtension: "json", subdirectory: "Stamps"),
                  let data = try? Data(contentsOf: url),
                  let definitions = try? JSONDecoder().decode([BuiltinStampDefinition].self, from: data),
                  !definitions.isEmpty else {
                continue
            }
            return definitions
        }
        return []
    }


    private func mapStamp(_ row: PersistentStamp) -> Stamp {
        Stamp(
            id: row.id,
            name: row.name,
            kind: StampKind(rawValue: row.kindRaw) ?? .systemSymbol,
            imageLocation: row.imageLocation,
            isBuiltin: row.isBuiltin,
            lastUsedAt: row.lastUsedAt,
            sortOrder: row.sortOrder
        )
    }

    private func mapEvent(_ row: PersistentEventSeries) -> Event {
        let rule: WeeklyRecurrenceRule?
        if let recurrenceStartDate = row.recurrenceStartDate {
            rule = WeeklyRecurrenceRule(
                startDate: recurrenceStartDate,
                endDate: row.recurrenceEndDate,
                weekdays: Set(row.recurrenceWeekdays),
                skipHolidays: row.recurrenceSkipHolidays
            )
        } else {
            rule = nil
        }

        return Event(
            id: row.id,
            title: row.title,
            stampId: row.stampId,
            childScope: ChildScope(rawValue: row.childScopeRaw) ?? .both,
            visibility: Visibility(rawValue: row.visibilityRaw) ?? .published,
            isAllDay: row.isAllDay,
            startDateTime: row.startDateTime,
            durationMinutes: row.durationMinutes,
            recurrenceRule: rule,
            createdAt: row.createdAt,
            updatedAt: row.updatedAt
        )
    }

    private func mapException(_ row: PersistentEventException) -> EventException {
        let decoder = JSONDecoder()
        let overrideEvent = row.overrideEventData.flatMap { try? decoder.decode(Event.self, from: $0) }
        let splitRule = row.splitRuleData.flatMap { try? decoder.decode(WeeklyRecurrenceRule.self, from: $0) }
        return EventException(
            id: row.id,
            eventId: row.eventId,
            occurrenceDate: row.occurrenceDate,
            kind: ExceptionKind(rawValue: row.kindRaw) ?? .override,
            overrideEvent: overrideEvent,
            splitRule: splitRule
        )
    }
}

#endif
