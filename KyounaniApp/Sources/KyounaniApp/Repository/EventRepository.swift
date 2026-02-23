#if canImport(SwiftUI)
import Foundation

public protocol EventRepository {
    func fetchEvents() -> [Event]
    func fetchExceptions() -> [EventException]
    func save(event: Event)
    func save(exception: EventException)
    func delete(eventID: UUID)
}

public final class InMemoryEventRepository: EventRepository, ObservableObject {
    @Published public private(set) var events: [Event]
    @Published public private(set) var exceptions: [EventException]

    public init(events: [Event] = [], exceptions: [EventException] = []) {
        self.events = events
        self.exceptions = exceptions
    }

    public func fetchEvents() -> [Event] { events }
    public func fetchExceptions() -> [EventException] { exceptions }

    public func save(event: Event) {
        if let i = events.firstIndex(where: { $0.id == event.id }) {
            events[i] = event
        } else {
            events.append(event)
        }
    }

    public func save(exception: EventException) {
        if let i = exceptions.firstIndex(where: { $0.id == exception.id }) {
            exceptions[i] = exception
        } else {
            exceptions.append(exception)
        }
    }

    public func delete(eventID: UUID) {
        events.removeAll { $0.id == eventID }
        exceptions.removeAll { $0.eventId == eventID }
    }
}

#endif
