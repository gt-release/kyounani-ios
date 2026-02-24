#if canImport(SwiftUI)
import SwiftUI

public struct EventEditorView: View {
    public enum Mode {
        case create
        case edit
    }

    private enum StampSortMode: String, CaseIterable {
        case recent
        case name

        var label: String {
            switch self {
            case .recent:
                return "最近順"
            case .name:
                return "名前順"
            }
        }
    }

    public struct EditScopeSummary {
        public let title: String
        public let description: String

        public init(title: String, description: String) {
            self.title = title
            self.description = description
        }
    }

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var stampStore: StampStore

    private let mode: Mode
    private let onSave: (Event) -> Void
    private let onDelete: (() -> Void)?
    private let shouldDismissAfterSave: Bool
    private let editScopeSummary: EditScopeSummary?
    private let impactPreviewDates: [Date]
    private let impactCountEstimate: Int?
    private let onReselectScope: (() -> Void)?

    private let eventID: UUID
    private let createdAt: Date

    @State private var title: String
    @State private var stampId: UUID
    @State private var childScope: ChildScope
    @State private var visibility: Visibility
    @State private var isAllDay: Bool
    @State private var startDateTime: Date
    @State private var durationMinutes: Int

    @State private var recurrenceEnabled: Bool
    @State private var recurrenceStartDate: Date
    @State private var recurrenceHasEndDate: Bool
    @State private var recurrenceEndDate: Date
    @State private var recurrenceWeekdays: Set<Int>
    @State private var recurrenceSkipHolidays: Bool

    @State private var stampSearchText = ""
    @State private var stampSortMode: StampSortMode = .recent

    public init(
        mode: Mode,
        initialEvent: Event,
        shouldDismissAfterSave: Bool = true,
        editScopeSummary: EditScopeSummary? = nil,
        impactPreviewDates: [Date] = [],
        impactCountEstimate: Int? = nil,
        onSave: @escaping (Event) -> Void,
        onDelete: (() -> Void)? = nil,
        onReselectScope: (() -> Void)? = nil
    ) {
        self.mode = mode
        self.onSave = onSave
        self.onDelete = onDelete
        self.shouldDismissAfterSave = shouldDismissAfterSave
        self.editScopeSummary = editScopeSummary
        self.impactPreviewDates = impactPreviewDates
        self.impactCountEstimate = impactCountEstimate
        self.onReselectScope = onReselectScope

        eventID = initialEvent.id
        createdAt = initialEvent.createdAt

        _title = State(initialValue: initialEvent.title)
        _stampId = State(initialValue: initialEvent.stampId)
        _childScope = State(initialValue: initialEvent.childScope)
        _visibility = State(initialValue: initialEvent.visibility)
        _isAllDay = State(initialValue: initialEvent.isAllDay)
        _startDateTime = State(initialValue: initialEvent.startDateTime)
        _durationMinutes = State(initialValue: max(5, initialEvent.durationMinutes ?? 30))

        _recurrenceEnabled = State(initialValue: initialEvent.recurrenceRule != nil)
        _recurrenceStartDate = State(initialValue: initialEvent.recurrenceRule?.startDate ?? initialEvent.startDateTime)
        _recurrenceHasEndDate = State(initialValue: initialEvent.recurrenceRule?.endDate != nil)
        _recurrenceEndDate = State(initialValue: initialEvent.recurrenceRule?.endDate ?? initialEvent.startDateTime)
        _recurrenceWeekdays = State(initialValue: initialEvent.recurrenceRule?.weekdays ?? [Calendar.current.component(.weekday, from: initialEvent.startDateTime)])
        _recurrenceSkipHolidays = State(initialValue: initialEvent.recurrenceRule?.skipHolidays ?? false)
    }

    private var recentStamps: [Stamp] {
        stampStore.stamps
            .filter { $0.lastUsedAt != nil }
            .sorted { lhs, rhs in
                guard let lhsDate = lhs.lastUsedAt, let rhsDate = rhs.lastUsedAt else { return false }
                if lhsDate != rhsDate { return lhsDate > rhsDate }
                return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }
            .prefix(10)
            .map { $0 }
    }

    private var filteredAndSortedStamps: [Stamp] {
        let normalized = stampSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let filtered = stampStore.stamps.filter { stamp in
            normalized.isEmpty || stamp.name.localizedCaseInsensitiveContains(normalized)
        }

        switch stampSortMode {
        case .recent:
            return filtered.sorted { lhs, rhs in
                switch (lhs.lastUsedAt, rhs.lastUsedAt) {
                case let (left?, right?):
                    if left != right { return left > right }
                case (_?, nil):
                    return true
                case (nil, _?):
                    return false
                case (nil, nil):
                    break
                }

                if lhs.name != rhs.name {
                    return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
                }
                return lhs.id.uuidString < rhs.id.uuidString
            }
        case .name:
            return filtered.sorted { lhs, rhs in
                if lhs.name != rhs.name {
                    return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
                }
                return lhs.id.uuidString < rhs.id.uuidString
            }
        }
    }

    public var body: some View {
        NavigationStack {
            Form {
                if let editScopeSummary {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "scope")
                                    .foregroundStyle(.blue)
                                Text("編集スコープ: \(editScopeSummary.title)")
                                    .font(.headline)
                            }

                            Text(editScopeSummary.description)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            if let onReselectScope {
                                Button("範囲を選び直す") {
                                    onReselectScope()
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                if !impactPreviewDates.isEmpty {
                    Section("影響範囲プレビュー") {
                        Text(impactPreviewDescription)
                            .font(.subheadline)
                        if let impactCountEstimate {
                            Text("影響件数（概算）: \(impactCountEstimate)件")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("基本") {
                    TextField("タイトル", text: $title)

                    Picker("子ども対象", selection: $childScope) {
                        Text("息子").tag(ChildScope.son)
                        Text("娘").tag(ChildScope.daughter)
                        Text("両方").tag(ChildScope.both)
                    }

                    Picker("公開状態", selection: $visibility) {
                        Text("公開").tag(Visibility.published)
                        Text("下書き").tag(Visibility.draft)
                    }
                }

                Section("スタンプ") {
                    #if os(iOS)
                    TextField("スタンプを検索", text: $stampSearchText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    #else
                    TextField("スタンプを検索", text: $stampSearchText)
                        .autocorrectionDisabled()
                    #endif

                    Picker("並び替え", selection: $stampSortMode) {
                        ForEach(StampSortMode.allCases, id: \.self) { mode in
                            Text(mode.label).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if !recentStamps.isEmpty {
                    Section("最近使った") {
                        stampSelectionRows(recentStamps)
                    }
                }

                Section("すべて") {
                    if filteredAndSortedStamps.isEmpty {
                        Text("該当するスタンプがありません")
                            .foregroundStyle(.secondary)
                    } else {
                        stampSelectionRows(filteredAndSortedStamps)
                    }
                }

                Section("日時") {
                    Toggle("終日", isOn: $isAllDay)

                    DatePicker(
                        "開始",
                        selection: $startDateTime,
                        displayedComponents: isAllDay ? [.date] : [.date, .hourAndMinute]
                    )

                    if !isAllDay {
                        Stepper(value: $durationMinutes, in: 5...24*60, step: 5) {
                            Text("所要時間: \(durationMinutes)分")
                        }
                    }
                }

                Section("繰り返し") {
                    Toggle("週次で繰り返す", isOn: $recurrenceEnabled)

                    if recurrenceEnabled {
                        DatePicker("開始日", selection: $recurrenceStartDate, displayedComponents: .date)

                        Toggle("終了日を指定", isOn: $recurrenceHasEndDate)
                        if recurrenceHasEndDate {
                            DatePicker("終了日", selection: $recurrenceEndDate, displayedComponents: .date)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("曜日")
                            weekdaySelector
                        }

                        Toggle("祝日をスキップ", isOn: $recurrenceSkipHolidays)
                    }
                }

                if mode == .edit, let onDelete {
                    Section {
                        Button("削除", role: .destructive) {
                            onDelete()
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(mode == .create ? "予定を追加" : "予定を編集")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let resolvedStampId = stampStore.ensureStampIdForDisplay(stampId)
                        onSave(buildEvent(with: resolvedStampId))
                        if shouldDismissAfterSave {
                            dismiss()
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func stampSelectionRows(_ stamps: [Stamp]) -> some View {
        ForEach(stamps) { stamp in
            Button {
                stampId = stamp.id
            } label: {
                HStack(spacing: 12) {
                    EventTokenRenderer(event: previewEvent(stampId: stamp.id), showTitle: false, iconSize: 22)
                    Text(stamp.name)
                    Spacer()
                    if stamp.id == stampId {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.blue)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var impactPreviewDescription: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M/d(E)"
        let previewText = impactPreviewDates.map { formatter.string(from: $0) }.joined(separator: "、")
        return "この保存で影響する予定日: \(previewText)"
    }

    private var weekdaySelector: some View {
        HStack {
            ForEach(1...7, id: \.self) { weekday in
                Button(shortWeekdayText(weekday)) {
                    if recurrenceWeekdays.contains(weekday) {
                        if recurrenceWeekdays.count > 1 {
                            recurrenceWeekdays.remove(weekday)
                        }
                    } else {
                        recurrenceWeekdays.insert(weekday)
                    }
                }
                .buttonStyle(.bordered)
                .tint(recurrenceWeekdays.contains(weekday) ? .blue : .gray)
            }
        }
    }

    private func shortWeekdayText(_ weekday: Int) -> String {
        ["日", "月", "火", "水", "木", "金", "土"][weekday - 1]
    }

    private func previewEvent(stampId: UUID) -> Event {
        Event(
            id: eventID,
            title: title,
            stampId: stampId,
            childScope: childScope,
            visibility: visibility,
            isAllDay: isAllDay,
            startDateTime: startDateTime,
            durationMinutes: isAllDay ? nil : durationMinutes,
            recurrenceRule: nil,
            createdAt: createdAt,
            updatedAt: Date()
        )
    }

    private func buildEvent(with resolvedStampId: UUID) -> Event {
        let resolvedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "よてい" : title

        let recurrence: WeeklyRecurrenceRule?
        if recurrenceEnabled {
            recurrence = WeeklyRecurrenceRule(
                startDate: recurrenceStartDate,
                endDate: recurrenceHasEndDate ? recurrenceEndDate : nil,
                weekdays: recurrenceWeekdays,
                skipHolidays: recurrenceSkipHolidays
            )
        } else {
            recurrence = nil
        }

        return Event(
            id: eventID,
            title: resolvedTitle,
            stampId: resolvedStampId,
            childScope: childScope,
            visibility: visibility,
            isAllDay: isAllDay,
            startDateTime: startDateTime,
            durationMinutes: isAllDay ? nil : durationMinutes,
            recurrenceRule: recurrence,
            createdAt: createdAt,
            updatedAt: Date()
        )
    }
}

#endif
