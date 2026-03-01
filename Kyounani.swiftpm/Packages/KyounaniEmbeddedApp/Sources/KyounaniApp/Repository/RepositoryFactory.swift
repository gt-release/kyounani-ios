import Foundation

#if canImport(SwiftData)
import SwiftData
#endif

@MainActor
public enum RepositoryFactory {
    public static func makeDefaultRepository() -> EventRepositoryBase {
        if DiagnosticsCenter.isSafeModeEnabled {
            DiagnosticsCenter.setLastRepoTypeLabel(RepositoryKind.inMemory.rawValue)
            DiagnosticsCenter.breadcrumb(event: "repoType", detail: RepositoryKind.inMemory.rawValue + " (safeMode)")
            return InMemoryEventRepository()
        }

        #if canImport(SwiftData)
        do {
            let schema = Schema([PersistentStamp.self, PersistentEventSeries.self, PersistentEventException.self])
            let container = try ModelContainer(for: schema)
            DiagnosticsCenter.setLastRepoTypeLabel(RepositoryKind.swiftData.rawValue)
            DiagnosticsCenter.breadcrumb(event: "repoType", detail: RepositoryKind.swiftData.rawValue)
            return SwiftDataEventRepository(context: ModelContext(container))
        } catch {
            DiagnosticsCenter.setLastRepoTypeLabel(RepositoryKind.fileBacked.rawValue)
            DiagnosticsCenter.breadcrumb(event: "repoType", detail: RepositoryKind.fileBacked.rawValue + " fallback: \(error.localizedDescription)")
            return FileBackedEventRepository()
        }
        #else
        DiagnosticsCenter.setLastRepoTypeLabel(RepositoryKind.fileBacked.rawValue)
        DiagnosticsCenter.breadcrumb(event: "repoType", detail: RepositoryKind.fileBacked.rawValue)
        return FileBackedEventRepository()
        #endif
    }
}
