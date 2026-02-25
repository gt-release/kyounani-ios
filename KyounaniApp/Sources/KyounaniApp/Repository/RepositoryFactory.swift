import Foundation

#if canImport(SwiftData)
import SwiftData
#endif

@MainActor
public enum RepositoryFactory {
    public static func makeDefaultRepository() -> EventRepositoryBase {
        if DiagnosticsCenter.isSafeModeEnabled {
            DiagnosticsCenter.breadcrumb(event: "repoType", detail: RepositoryKind.inMemory.rawValue + " (safeMode)")
            return InMemoryEventRepository()
        }

        #if canImport(SwiftData)
        do {
            let schema = Schema([PersistentStamp.self, PersistentEventSeries.self, PersistentEventException.self])
            let container = try ModelContainer(for: schema)
            DiagnosticsCenter.breadcrumb(event: "repoType", detail: RepositoryKind.swiftData.rawValue)
            return SwiftDataEventRepository(context: ModelContext(container))
        } catch {
            DiagnosticsCenter.breadcrumb(event: "repoType", detail: RepositoryKind.fileBacked.rawValue + " fallback: \(error.localizedDescription)")
            return FileBackedEventRepository()
        }
        #else
        DiagnosticsCenter.breadcrumb(event: "repoType", detail: RepositoryKind.fileBacked.rawValue)
        return FileBackedEventRepository()
        #endif
    }
}
