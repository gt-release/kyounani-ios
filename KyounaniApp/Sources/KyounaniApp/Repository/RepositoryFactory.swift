import Foundation

#if canImport(SwiftData)
import SwiftData
#endif

@MainActor
public enum RepositoryFactory {
    public static func makeDefaultRepository() -> EventRepositoryBase {
        #if canImport(SwiftData)
        do {
            let schema = Schema([PersistentStamp.self, PersistentEventSeries.self, PersistentEventException.self])
            let container = try ModelContainer(for: schema)
            return SwiftDataEventRepository(context: ModelContext(container))
        } catch {
            return FileBackedEventRepository()
        }
        #else
        return FileBackedEventRepository()
        #endif
    }
}
