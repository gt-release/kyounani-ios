#if canImport(SwiftUI)
import SwiftUI

public struct ParentModeView: View {
    @EnvironmentObject private var appVM: AppViewModel
    @ObservedObject var repo: InMemoryEventRepository
    @State private var title = ""

    public init(repo: InMemoryEventRepository) {
        self.repo = repo
    }

    public var body: some View {
        NavigationStack {
            List {
                Section("クイック追加") {
                    quickButton("幼稚園")
                    quickButton("病院")
                    quickButton("公園")
                    quickButton("療育")
                }

                Section("予定") {
                    ForEach(repo.fetchEvents()) { event in
                        VStack(alignment: .leading) {
                            Text(event.title)
                            Text(event.visibility == .published ? "公開" : "下書き")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .onDelete { indexSet in
                        let events = repo.fetchEvents()
                        for i in indexSet {
                            repo.delete(eventID: events[i].id)
                        }
                    }
                }
            }
            .navigationTitle("親モード")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("ロック") { appVM.lockToChildMode() }
                }
            }
        }
    }

    private func quickButton(_ name: String) -> some View {
        Button(name) {
            let event = Event(
                title: name,
                stampId: UUID(),
                childScope: .both,
                visibility: .published,
                isAllDay: false,
                startDateTime: Date().addingTimeInterval(3600),
                durationMinutes: 60,
                recurrenceRule: nil
            )
            repo.save(event: event)
        }
    }
}

#endif
