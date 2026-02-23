import Foundation

@MainActor
public protocol EventRepository: AnyObject {
    func fetchEvents() -> [Event]
    func fetchExceptions() -> [EventException]
    func fetchStamps() -> [Stamp]
    func save(event: Event)
    func save(exception: EventException)
    func save(stamp: Stamp)
    func delete(eventID: UUID)
    func delete(stampID: UUID)
}

#if canImport(SwiftUI)
import SwiftUI

@MainActor
open class EventRepositoryBase: ObservableObject, EventRepository {
    public init() {}

    open func fetchEvents() -> [Event] { [] }
    open func fetchExceptions() -> [EventException] { [] }
    open func fetchStamps() -> [Stamp] { [] }
    open func save(event: Event) {}
    open func save(exception: EventException) {}
    open func save(stamp: Stamp) {}
    open func delete(eventID: UUID) {}
    open func delete(stampID: UUID) {}
}
#else
@MainActor
open class EventRepositoryBase: EventRepository {
    public init() {}

    open func fetchEvents() -> [Event] { [] }
    open func fetchExceptions() -> [EventException] { [] }
    open func fetchStamps() -> [Stamp] { [] }
    open func save(event: Event) {}
    open func save(exception: EventException) {}
    open func save(stamp: Stamp) {}
    open func delete(eventID: UUID) {}
    open func delete(stampID: UUID) {}
}
#endif

@MainActor
public final class InMemoryEventRepository: EventRepositoryBase {
    public private(set) var events: [Event]
    public private(set) var exceptions: [EventException]
    public private(set) var stamps: [Stamp]

    public init(events: [Event] = [], exceptions: [EventException] = [], stamps: [Stamp] = []) {
        self.events = events
        self.exceptions = exceptions
        self.stamps = stamps
        super.init()
    }

    public override func fetchEvents() -> [Event] { events }
    public override func fetchExceptions() -> [EventException] { exceptions }
    public override func fetchStamps() -> [Stamp] { stamps }

    public override func save(event: Event) {
        #if canImport(SwiftUI)
        objectWillChange.send()
        #endif
        if let i = events.firstIndex(where: { $0.id == event.id }) {
            events[i] = event
        } else {
            events.append(event)
        }
    }

    public override func save(exception: EventException) {
        #if canImport(SwiftUI)
        objectWillChange.send()
        #endif
        if let i = exceptions.firstIndex(where: { $0.id == exception.id }) {
            exceptions[i] = exception
        } else {
            exceptions.append(exception)
        }
    }

    public override func save(stamp: Stamp) {
        #if canImport(SwiftUI)
        objectWillChange.send()
        #endif
        if let i = stamps.firstIndex(where: { $0.id == stamp.id }) {
            stamps[i] = stamp
        } else {
            stamps.append(stamp)
        }
    }

    public override func delete(eventID: UUID) {
        #if canImport(SwiftUI)
        objectWillChange.send()
        #endif
        events.removeAll { $0.id == eventID }
        exceptions.removeAll { $0.eventId == eventID }
    }

    public override func delete(stampID: UUID) {
        #if canImport(SwiftUI)
        objectWillChange.send()
        #endif
        stamps.removeAll { $0.id == stampID }
    }
}
