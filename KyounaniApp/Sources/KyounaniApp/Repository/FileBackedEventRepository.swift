import Foundation

private struct LegacyPersistedStamp: Codable {
    var id: UUID
    var name: String
    var imageFilename: String
}

@MainActor
public final class FileBackedEventRepository: EventRepositoryBase {
    private var events: [Event]
    private var exceptions: [EventException]
    private var stamps: [Stamp]

    public override init() {
        self.events = []
        self.exceptions = []
        self.stamps = []
        super.init()
        loadFromDisk()
    }

    public override func fetchEvents() -> [Event] { events }
    public override func fetchExceptions() -> [EventException] { exceptions }
    public override func fetchStamps() -> [Stamp] { stamps }

    public override func save(event: Event) {
        notifyChange()
        if let i = events.firstIndex(where: { $0.id == event.id }) {
            events[i] = event
        } else {
            events.append(event)
        }
        persistEvents()
    }

    public override func save(exception: EventException) {
        notifyChange()
        if let i = exceptions.firstIndex(where: { $0.id == exception.id }) {
            exceptions[i] = exception
        } else {
            exceptions.append(exception)
        }
        persistExceptions()
    }

    public override func save(stamp: Stamp) {
        notifyChange()
        if let i = stamps.firstIndex(where: { $0.id == stamp.id }) {
            stamps[i] = stamp
        } else {
            stamps.append(stamp)
        }
        persistStamps()
    }

    public override func delete(eventID: UUID) {
        notifyChange()
        events.removeAll { $0.id == eventID }
        exceptions.removeAll { $0.eventId == eventID }
        persistEvents()
        persistExceptions()
    }

    public override func delete(stampID: UUID) {
        notifyChange()
        stamps.removeAll { $0.id == stampID }
        persistStamps()
    }

    private func loadFromDisk() {
        events = decode([Event].self, from: eventsURL()) ?? []
        exceptions = decode([EventException].self, from: exceptionsURL()) ?? []
        stamps = loadStampsFromDisk()
    }

    private func loadStampsFromDisk() -> [Stamp] {
        if let current = decode([Stamp].self, from: stampsURL()) {
            return current
        }

        guard let legacy = decode([LegacyPersistedStamp].self, from: stampsURL()) else {
            return []
        }

        let migrated = legacy.map {
            Stamp(id: $0.id, name: $0.name, kind: .customImage, imageLocation: $0.imageFilename, isBuiltin: false)
        }
        encode(migrated, to: stampsURL())
        return migrated
    }

    private func persistEvents() {
        encode(events, to: eventsURL())
    }

    private func persistExceptions() {
        encode(exceptions, to: exceptionsURL())
    }

    private func persistStamps() {
        encode(stamps, to: stampsURL())
    }

    private func decode<T: Decodable>(_ type: T.Type, from url: URL) -> T? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private func encode<T: Encodable>(_ value: T, to url: URL) {
        do {
            try ensureAppSupportDirectory()
            let data = try JSONEncoder().encode(value)
            try data.write(to: url, options: .atomic)
        } catch {
            // Keep app usable in fallback mode even if persistence fails.
        }
    }

    private func notifyChange() {
        #if canImport(SwiftUI)
        objectWillChange.send()
        #endif
    }

    private func ensureAppSupportDirectory() throws {
        let dir = appSupportDirectory()
        if !FileManager.default.fileExists(atPath: dir.path) {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
    }

    private func appSupportDirectory() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return base.appendingPathComponent("Kyounani", isDirectory: true)
    }

    private func eventsURL() -> URL { appSupportDirectory().appendingPathComponent("events.json") }
    private func exceptionsURL() -> URL { appSupportDirectory().appendingPathComponent("exceptions.json") }
    private func stampsURL() -> URL { appSupportDirectory().appendingPathComponent("stamps.json") }
}
