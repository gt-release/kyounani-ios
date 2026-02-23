#if canImport(SwiftUI)
import SwiftUI
import UniformTypeIdentifiers

#if canImport(PhotosUI)
import PhotosUI
#endif

public struct ParentModeView: View {
    @EnvironmentObject private var appVM: AppViewModel
    @EnvironmentObject private var stampStore: StampStore
    @ObservedObject var repo: EventRepositoryBase

    @State private var showingFileImporter = false
    #if canImport(PhotosUI)
    @State private var selectedPhotoItem: PhotosPickerItem?
    #endif
    @State private var newStampName = ""
    @State private var creatingEvent = false
    @State private var editingEvent: Event?

    public init(repo: EventRepositoryBase) {
        self.repo = repo
    }

    public var body: some View {
        NavigationStack {
            List {
                Section("クイック追加") {
                    quickButton("幼稚園", stampId: stampStore.defaultStampId)
                    quickButton("病院", stampId: UUID(uuidString: "22222222-2222-2222-2222-222222222222") ?? stampStore.defaultStampId)
                    quickButton("公園", stampId: UUID(uuidString: "33333333-3333-3333-3333-333333333333") ?? stampStore.defaultStampId)
                    quickButton("療育", stampId: UUID(uuidString: "44444444-4444-4444-4444-444444444444") ?? stampStore.defaultStampId)
                }

                Section("スタンプ追加") {
                    TextField("スタンプ名", text: $newStampName)

                    Button("Files から取り込み") {
                        showingFileImporter = true
                    }

                    #if canImport(PhotosUI)
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
                        Text("Photos から取り込み")
                    }
                    #endif
                }

                Section("スタンプ一覧") {
                    ForEach(stampStore.stamps) { stamp in
                        HStack(spacing: 12) {
                            if let image = stampStore.image(for: stamp) {
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 32, height: 32)
                                    .clipShape(RoundedRectangle(cornerRadius: 7))
                            } else {
                                RoundedRectangle(cornerRadius: 7)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 32, height: 32)
                            }

                            VStack(alignment: .leading) {
                                Text(stamp.name)
                                Text(stamp.kind == .systemSymbol ? "builtin" : "user")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete(perform: deleteUserStamp)
                }

                Section("予定") {
                    ForEach(repo.fetchEvents().sorted(by: { $0.startDateTime < $1.startDateTime })) { event in
                        Button {
                            editingEvent = event
                        } label: {
                            HStack {
                                EventTokenRenderer(event: event, showTitle: false, iconSize: 24)
                                VStack(alignment: .leading) {
                                    Text(event.title)
                                    Text(event.visibility == .published ? "公開" : "下書き")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete { indexSet in
                        let events = repo.fetchEvents().sorted(by: { $0.startDateTime < $1.startDateTime })
                        for i in indexSet {
                            repo.delete(eventID: events[i].id)
                        }
                    }
                }
            }
            .fileImporter(isPresented: $showingFileImporter, allowedContentTypes: [.image]) { result in
                guard case .success(let url) = result,
                      let data = readImportedImageData(from: url) else {
                    return
                }
                _ = stampStore.addUserStamp(name: resolvedStampName(prefix: "files"), imageData: data)
            }
            #if canImport(PhotosUI)
            .onChange(of: selectedPhotoItem) { item in
                guard let item else { return }
                Task {
                    guard let data = try? await item.loadTransferable(type: Data.self) else { return }
                    await MainActor.run {
                        _ = stampStore.addUserStamp(name: resolvedStampName(prefix: "photo"), imageData: data)
                        selectedPhotoItem = nil
                    }
                }
            }
            #endif
            .navigationTitle("親モード")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("＋追加") {
                        creatingEvent = true
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("ロック") { appVM.lockToChildMode() }
                }
            }
            .sheet(isPresented: $creatingEvent) {
                EventEditorView(mode: .create, initialEvent: draftEvent(), onSave: { event in
                    repo.save(event: event)
                    stampStore.markStampUsed(event.stampId)
                })
                .environmentObject(stampStore)
            }
            .sheet(item: $editingEvent) { event in
                EventEditorView(mode: .edit, initialEvent: event, onSave: { updated in
                    repo.save(event: updated)
                    stampStore.markStampUsed(updated.stampId)
                }, onDelete: {
                    repo.delete(eventID: event.id)
                })
                .environmentObject(stampStore)
            }
        }
    }

    private func resolvedStampName(prefix: String) -> String {
        let trimmed = newStampName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "\(prefix)-\(stampStore.stamps.count + 1)" : trimmed
    }

    private func deleteUserStamp(_ indexSet: IndexSet) {
        let targetIDs = indexSet.compactMap { index -> UUID? in
            guard stampStore.stamps.indices.contains(index) else { return nil }
            let stamp = stampStore.stamps[index]
            return stamp.kind == .customImage ? stamp.id : nil
        }

        for id in targetIDs {
            _ = stampStore.deleteUserStamp(id: id)
        }
    }

    private func readImportedImageData(from url: URL) -> Data? {
        let needsScopedAccess = url.startAccessingSecurityScopedResource()
        defer {
            if needsScopedAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        return try? Data(contentsOf: url)
    }

    private func quickButton(_ name: String, stampId: UUID) -> some View {
        Button(name) {
            let event = Event(
                title: name,
                stampId: stampStore.ensureStampIdForDisplay(stampId),
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

    private func draftEvent() -> Event {
        Event(
            title: "",
            stampId: stampStore.defaultStampId,
            childScope: .both,
            visibility: .published,
            isAllDay: false,
            startDateTime: Date(),
            durationMinutes: 60,
            recurrenceRule: nil
        )
    }
}

#endif
