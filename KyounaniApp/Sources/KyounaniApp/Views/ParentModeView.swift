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

    @State private var showingImageImporter = false
    @State private var showingBackupExporter = false
    @State private var showingExportPassphraseSheet = false
    @State private var showingBackupImporter = false
    @State private var backupExportPassphrase = ""
    @State private var backupImportPassphrase = ""
    @State private var backupFileForExport = BackupFileDocument()
    @State private var importedBackupData: Data?
    @State private var pendingImportPayload: BackupPayload?
    @State private var backupStatusMessage = ""
    @State private var showingBackupStatusAlert = false
    @State private var showingResetConfirmation = false

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
        parentNavigationView
    }

    private var parentNavigationView: some View {
        NavigationStack {
            parentList
        }
        .fileImporter(isPresented: $showingImageImporter, allowedContentTypes: [.image]) { result in
            guard case .success(let url) = result,
                  let data = readImportedImageData(from: url) else {
                return
            }
            _ = stampStore.addUserStamp(name: resolvedStampName(prefix: "files"), imageData: data)
        }
        .fileExporter(
            isPresented: $showingBackupExporter,
            document: backupFileForExport,
            contentType: .kyounaniBackup,
            defaultFilename: "kyounani-backup"
        ) { result in
            switch result {
            case .success:
                showBackupStatus("バックアップを書き出しました")
            case .failure:
                showBackupStatus("バックアップの保存に失敗しました")
            }
        }
        .fileImporter(isPresented: $showingBackupImporter, allowedContentTypes: [.kyounaniBackup, .data]) { result in
            guard case .success(let url) = result,
                  let data = readImportedImageData(from: url) else {
                showBackupStatus("バックアップファイルの読み込みに失敗しました")
                return
            }
            importedBackupData = data
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
        .sheet(isPresented: $showingExportPassphraseSheet) {
            backupExportPassphraseSheet
        }
        .sheet(isPresented: Binding(get: { importedBackupData != nil && pendingImportPayload == nil }, set: { if !$0 { importedBackupData = nil } })) {
            backupImportPassphraseSheet
        }
        .sheet(item: Binding(get: {
            pendingImportPayload.map { PendingPayloadWrapper(payload: $0) }
        }, set: { wrapper in
            pendingImportPayload = wrapper?.payload
        })) { wrapper in
            backupImportSummarySheet(payload: wrapper.payload)
        }
        .alert("バックアップ", isPresented: $showingBackupStatusAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(backupStatusMessage)
        }
        .confirmationDialog("本当にデータを全削除しますか？", isPresented: $showingResetConfirmation, titleVisibility: .visible) {
            Button("全削除する", role: .destructive) {
                resetAllData()
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("予定・例外・スタンプ（追加画像含む）をすべて削除します")
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
            parentToolbar
        }
    }

    private var parentList: some View {
        List {
            Section("見やすさ") {
                Picker("テーマ", selection: $appVM.themePreset) {
                    ForEach(ThemePreset.allCases) { preset in
                        Text(preset.displayName).tag(preset)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("バックアップ") {
                Button("バックアップを書き出す") {
                    showingExportPassphraseSheet = true
                }

                Button("バックアップから復元") {
                    showingBackupImporter = true
                }
            }

            Section("データ管理") {
                Button("データを全削除（リセット）", role: .destructive) {
                    showingResetConfirmation = true
                }
            }

            Section("診断") {
                NavigationLink("Diagnostics") {
                    DiagnosticsView(repo: repo)
                }
            }

            Section("クイック追加") {
                quickButton("幼稚園", stampId: stampStore.defaultStampId)
                quickButton("病院", stampId: UUID(uuidString: "22222222-2222-2222-2222-222222222222") ?? stampStore.defaultStampId)
                quickButton("公園", stampId: UUID(uuidString: "33333333-3333-3333-3333-333333333333") ?? stampStore.defaultStampId)
                quickButton("療育", stampId: UUID(uuidString: "44444444-4444-4444-4444-444444444444") ?? stampStore.defaultStampId)
            }

            Section("スタンプ追加") {
                TextField("スタンプ名", text: $newStampName)

                Button("Files から取り込み") {
                    showingImageImporter = true
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
    }

    @ToolbarContent
    private var parentToolbar: some ToolbarContent {
        #if os(iOS)
        ToolbarItem(placement: .topBarLeading) {
            Button("＋追加") {
                creatingEvent = true
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button("ロック") { appVM.lockToChildMode() }
        }
        #else
        ToolbarItem(placement: .cancellationAction) {
            Button("＋追加") {
                creatingEvent = true
            }
        }
        ToolbarItem(placement: .confirmationAction) {
            Button("ロック") { appVM.lockToChildMode() }
        }
        #endif
    }
    private var backupExportPassphraseSheet: some View {
        NavigationStack {
            Form {
                Section("暗号化パスフレーズ") {
                    SecureField("パスフレーズ", text: $backupExportPassphrase)
                    Text("6桁数字または任意文字列を設定できます")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("バックアップ書き出し")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        showingExportPassphraseSheet = false
                        backupExportPassphrase = ""
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("書き出し") {
                        showingExportPassphraseSheet = false
                        prepareBackupFileForExport()
                    }
                }
            }
        }
    }

    private var backupImportPassphraseSheet: some View {
        NavigationStack {
            Form {
                Section("復元パスフレーズ") {
                    SecureField("パスフレーズ", text: $backupImportPassphrase)
                }
            }
            .navigationTitle("バックアップ復号")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        importedBackupData = nil
                        backupImportPassphrase = ""
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("次へ") {
                        decodeImportedBackup()
                    }
                }
            }
        }
    }

    private func backupImportSummarySheet(payload: BackupPayload) -> some View {
        let summary = BackupCryptoService.summarize(payload: payload)
        return NavigationStack {
            Form {
                Section("復元内容") {
                    Text("スタンプ: \(summary.stampCount)件")
                    Text("予定: \(summary.eventCount)件")
                    Text("例外: \(summary.exceptionCount)件")
                }
                Section {
                    Text("復元は上書きです。現在のデータはすべて置き換えられます。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("復元確認")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        pendingImportPayload = nil
                        importedBackupData = nil
                        backupImportPassphrase = ""
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("復元実行") {
                        runImport(payload: payload)
                    }
                }
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

    private func prepareBackupFileForExport() {
        do {
            let payload = try makeBackupPayload()
            let encrypted = try BackupCryptoService.exportEncryptedData(payload: payload, passphrase: backupExportPassphrase)
            backupFileForExport = BackupFileDocument(data: encrypted)
            backupExportPassphrase = ""
            showingBackupExporter = true
        } catch {
            showBackupStatus(error.localizedDescription)
        }
    }

    private func makeBackupPayload() throws -> BackupPayload {
        let stamps = stampStore.stamps.map { stamp -> StampBackupEntry in
            if stamp.kind == .customImage,
               let imageData = stampStore.customImageData(filename: stamp.imageLocation) {
                return StampBackupEntry(stamp: stamp, customImageBase64: imageData.base64EncodedString())
            }
            return StampBackupEntry(stamp: stamp, customImageBase64: nil)
        }

        return BackupPayload(
            stamps: stamps,
            events: repo.fetchEvents(),
            exceptions: repo.fetchExceptions()
        )
    }

    private func decodeImportedBackup() {
        guard let data = importedBackupData else {
            showBackupStatus("バックアップファイルが選択されていません")
            return
        }

        do {
            let payload = try BackupCryptoService.decryptPayload(from: data, passphrase: backupImportPassphrase)
            pendingImportPayload = payload
        } catch {
            showBackupStatus(error.localizedDescription)
        }
    }

    private func runImport(payload: BackupPayload) {
        do {
            let imported = try rebuildImportedStamps(payload.stamps)
            repo.replaceAll(events: payload.events, exceptions: payload.exceptions, stamps: imported)
            stampStore.reload()
            pendingImportPayload = nil
            importedBackupData = nil
            backupImportPassphrase = ""
            showBackupStatus("バックアップを復元しました")
        } catch {
            showBackupStatus(error.localizedDescription)
        }
    }

    private func rebuildImportedStamps(_ entries: [StampBackupEntry]) throws -> [Stamp] {
        var importedStamps: [Stamp] = []

        for entry in entries {
            var stamp = entry.stamp
            if stamp.kind == .customImage {
                guard let base64 = entry.customImageBase64,
                      let data = Data(base64Encoded: base64),
                      let filename = stampStore.storeCustomImageData(data, suggestedFilename: stamp.id.uuidString) else {
                    throw BackupCryptoError.invalidBackupFile
                }
                stamp.imageLocation = filename
            }
            importedStamps.append(stamp)
        }

        return importedStamps
    }

    private func resetAllData() {
        repo.replaceAll(events: [], exceptions: [], stamps: [])
        stampStore.removeAllCustomImageFiles()
        stampStore.reseedBuiltinStampsIfNeeded()
        stampStore.reload()
        showBackupStatus("データを全削除しました。必要な内容を作り直してください")
    }

    private func showBackupStatus(_ message: String) {
        backupStatusMessage = message
        showingBackupStatusAlert = true
    }
}

private struct PendingPayloadWrapper: Identifiable {
    let payload: BackupPayload
    var id: Date { payload.exportedAt }
}

#endif
